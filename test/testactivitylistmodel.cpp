/*
 * Copyright (C) by Claudio Cambra <claudio.cambra@nextcloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

#include "gui/tray/activitylistmodel.h"

#include "account.h"
#include "accountstate.h"
#include "syncenginetestutils.h"

#include <QAbstractItemModelTester>
#include <QDesktopServices>
#include <QSignalSpy>
#include <QTest>

static QByteArray fake404Response = R"(
{"ocs":{"meta":{"status":"failure","statuscode":404,"message":"Invalid query, please check the syntax. API specifications are here: http:\/\/www.freedesktop.org\/wiki\/Specifications\/open-collaboration-services.\n"},"data":[]}}
)";

static QByteArray fake400Response = R"(
{"ocs":{"meta":{"status":"failure","statuscode":400,"message":"Parameter is incorrect.\n"},"data":[]}}
)";

static QByteArray fake500Response = R"(
{"ocs":{"meta":{"status":"failure","statuscode":500,"message":"Internal Server Error.\n"},"data":[]}}
)";

class FakeRemoteActivityStorage
{
public:
    FakeRemoteActivityStorage() = default;

    static FakeRemoteActivityStorage *instance()
    {
        if (!_instance) {
            _instance = new FakeRemoteActivityStorage();
            _instance->init();
        }

        return _instance;
    };

    static void destroy()
    {
        if (_instance) {
            delete _instance;
        }

        _instance = nullptr;
    }

    void init()
    {
        if (!_activityData.isEmpty()) {
            return;
        }

        _metaSuccess = {{QStringLiteral("status"), QStringLiteral("ok")}, {QStringLiteral("statuscode"), 200},
            {QStringLiteral("message"), QStringLiteral("OK")}};

        initActivityData();
    }

    void initActivityData()
    {
        // Insert activity data
        for (quint32 i = 0; i < _numItemsToInsert; i++) {
            _startingId++;

            QJsonObject activity;
            activity.insert(QStringLiteral("object_type"), "files");
            activity.insert(QStringLiteral("activity_id"), _startingId);
            activity.insert(QStringLiteral("type"), QStringLiteral("file"));
            activity.insert(QStringLiteral("subject"), QStringLiteral("You created %1.txt").arg(i));
            activity.insert(QStringLiteral("message"), QStringLiteral(""));
            activity.insert(QStringLiteral("object_name"), QStringLiteral("%1.txt").arg(i));
            activity.insert(QStringLiteral("link"), QStringLiteral("http://example.de/index.php/f/%1").arg(_startingId));
            activity.insert(QStringLiteral("datetime"), QDateTime::currentDateTime().toString(Qt::ISODate));
            activity.insert(QStringLiteral("icon"), QStringLiteral("http://example.de/apps/files/img/add-color.svg"));

            _activityData.push_back(activity);
        }

        // Insert notification data
        /*for (quint32 i = 0; i < _numItemsToInsert; i++) {
            _startingId++;
            QJsonObject activity;
            activity.insert(QStringLiteral("activity_id"), _startingId);
            //activity.insert(QStringLiteral("type"), "Notification"

            _activityData.push_back(activity);
        }*/
    }

    const QByteArray activityJsonData(int sinceId, int limit)
    {
        QJsonArray data;

        for(int dataIndex = _activityData.size() - 1, iteration = 0;
            dataIndex > 0 && iteration < limit;
            dataIndex--, iteration ++) {

            if(_activityData[dataIndex].toObject().value(QStringLiteral("activity_id")).toInt() < sinceId) {
                data.append(_activityData[dataIndex]);
            }
        }

        QJsonObject root;
        QJsonObject ocs;
        ocs.insert(QStringLiteral("data"), data);
        root.insert(QStringLiteral("ocs"), ocs);

        return QJsonDocument(root).toJson();
    }

private:
    static FakeRemoteActivityStorage *_instance;
    QJsonArray _activityData;
    QVariantMap _metaSuccess;
    quint32 _numItemsToInsert = 30;
    int _startingId = 90000;
};

class TestActivityListModel : public QObject
{
    Q_OBJECT

public:
    TestActivityListModel() = default;

    QScopedPointer<FakeQNAM> fakeQnam;
    OCC::AccountPtr account;
    QScopedPointer<OCC::AccountState> accountState;
    QScopedPointer<OCC::ActivityListModel> model;
    QScopedPointer<QAbstractItemModelTester> modelTester;

    static const int searchResultsReplyDelay = 100;

private slots:
    void initTestCase()
    {
        fakeQnam.reset(new FakeQNAM({}));
        account = OCC::Account::create();
        account->setCredentials(new FakeCredentials{fakeQnam.data()});
        account->setUrl(QUrl(("http://example.de")));

        accountState.reset(new OCC::AccountState(account));

        fakeQnam->setOverride([this](QNetworkAccessManager::Operation op, const QNetworkRequest &req, QIODevice *device) {
            Q_UNUSED(device);
            QNetworkReply *reply = nullptr;

            const auto urlQuery = QUrlQuery(req.url());
            const auto format = urlQuery.queryItemValue(QStringLiteral("format"));
            const auto since = urlQuery.queryItemValue(QStringLiteral("since")).toInt();
            const auto limit = urlQuery.queryItemValue(QStringLiteral("limit")).toInt();
            const auto path = req.url().path();

            if (!req.url().toString().startsWith(accountState->account()->url().toString())) {
                reply = new FakeErrorReply(op, req, this, 404, fake404Response);
            }
            if (format != QStringLiteral("json")) {
                reply = new FakeErrorReply(op, req, this, 400, fake400Response);
            }

            // handle search for provider
            if (path.startsWith(QStringLiteral("/ocs/v2.php/apps/activity/api/v2/activity"))) {
                const auto pathSplit = path.mid(QString(QStringLiteral("/ocs/v2.php/apps/activity/api/v2/activity")).size()).split(QLatin1Char('/'), Qt::SkipEmptyParts);

                if (!pathSplit.isEmpty()) {
                    reply = new FakePayloadReply(op, req, FakeRemoteActivityStorage::instance()->activityJsonData(since, limit), searchResultsReplyDelay, fakeQnam.data());
                }
            }

            if (!reply) {
                return qobject_cast<QNetworkReply*>(new FakeErrorReply(op, req, this, 404, QByteArrayLiteral("{error: \"Not found!\"}")));
            }

            return reply;
        });

        model.reset(new OCC::ActivityListModel(accountState.data()));

        modelTester.reset(new QAbstractItemModelTester(model.data()));
    };
    // Test receiving activity from server
    // Test receiving activity from local user action
    // Test removing activity from list
};

QTEST_MAIN(TestActivityListModel)
#include "testactivitylistmodel.moc"
