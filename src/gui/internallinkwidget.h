/*
 * Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>
 * Copyright (C) 2015 by Klaas Freitag <freitag@owncloud.com>
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

#ifndef INTERNALLINKWIDGET_H
#define INTERNALLINKWIDGET_H

#include "accountfwd.h"
#include "sharepermissions.h"
#include "QProgressIndicator.h"
#include <QDialog>
#include <QSharedPointer>
#include <QList>
#include <QToolButton>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QWidgetAction>

class QMenu;
class QTableWidgetItem;

namespace OCC {

namespace Ui {
    class InternalLinkWidget;
}

class AbstractCredentials;
class SyncResult;
class LinkShare;
class Share;
class ElidedLabel;

/**
 * @brief The ShareDialog class
 * @ingroup gui
 */
class InternalLinkWidget : public QWidget
{
    Q_OBJECT

public:
    explicit InternalLinkWidget(AccountPtr account,
        const QString &sharePath,
        const QString &localPath,
        QWidget *parent = nullptr);
    ~InternalLinkWidget() override;

    void toggleButton(bool show);
    void setupUiOptions();

public slots:
    void slotStyleChanged();

private slots:
    void slotCopyInternalLink(const bool clicked) const;

private:
    void displayError(const QString &errMsg);

    void customizeStyle();

    Ui::InternalLinkWidget *_ui;
    AccountPtr _account;
    QString _sharePath;
    QString _localPath;
    QString _shareUrl;

    bool _isFile;

    QPushButton *_copyInternalLinkButton{};
};
}

#endif // INTERNALLINKWIDGET_H
