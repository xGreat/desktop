/*
 * Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
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

#include "generalsettings.h"
#include "ui_generalsettings.h"

#include "theme.h"
#include "configfile.h"
#include "application.h"
#include "configfile.h"
#include "owncloudsetupwizard.h"
#include "synclogdialog.h"

#if defined(BUILD_UPDATER)
#include "updater/updater.h"
#include "updater/ocupdater.h"
#endif

#include "ignorelisteditor.h"
#include "common/utility.h"

#include "config.h"

#include "legalnotice.h"

#include <QNetworkProxy>
#include <QDir>
#include <QScopedValueRollback>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#include "vfs_windows.h"
#endif

#ifdef Q_OS_MAC
#include "vfs_mac.h"
#endif

#define QTLEGACY (QT_VERSION < QT_VERSION_CHECK(5,9,0))

#if !(QTLEGACY)
#include <QOperatingSystemVersion>
#endif

namespace OCC {

GeneralSettings::GeneralSettings(QWidget *parent)
    : QWidget(parent)
    , _ui(new Ui::GeneralSettings)
{
    _ui->setupUi(this);

    connect(_ui->serverNotificationsCheckBox, &QAbstractButton::toggled,
        this, &GeneralSettings::slotToggleOptionalServerNotifications);
    _ui->serverNotificationsCheckBox->setToolTip(tr("Server notifications that require attention."));

    // TODO: show checkbox once the virtual drive is NOT a experimental feature
    // #ifndef defined(Q_OS_UNIX)
#if 0
    _ui->virtualFileSystemCheckbox->hide();
    connect(_ui->virtualFileSystemCheckbox, &QAbstractButton::toggled,
        this, &GeneralSettings::slotToggleOptionalVirtualFileSystem);
    connect(this, &GeneralSettings::mountVirtualDrive, AccountManager::instance(), &AccountManager::mountVirtualDriveForAccount);
    _ui->virtualFileSystemCheckbox->setToolTip(tr("Sync files on demand."));
#endif

    connect(_ui->showInExplorerNavigationPaneCheckBox, &QAbstractButton::toggled, this, &GeneralSettings::slotShowInExplorerNavigationPane);

    // Rename 'Explorer' appropriately on non-Windows
#ifdef Q_OS_MAC
    QString txt = _ui->showInExplorerNavigationPaneCheckBox->text();
    txt.replace(QString::fromLatin1("Explorer"), QString::fromLatin1("Finder"));
    _ui->showInExplorerNavigationPaneCheckBox->setText(txt);
#endif

    _ui->autostartCheckBox->setChecked(Utility::hasLaunchOnStartup(Theme::instance()->appName()));
    connect(_ui->autostartCheckBox, &QAbstractButton::toggled, this, &GeneralSettings::slotToggleLaunchOnStartup);

    // setup about section
    QString about = Theme::instance()->about();
    _ui->aboutLabel->setTextInteractionFlags(Qt::TextSelectableByMouse | Qt::TextBrowserInteraction);
    _ui->aboutLabel->setText(about);
    _ui->aboutLabel->setOpenExternalLinks(true);

    // About legal notice
    connect(_ui->legalNoticeButton, &QPushButton::clicked, this, &GeneralSettings::slotShowLegalNotice);

    loadMiscSettings();
    // updater info now set in: customizeStyle
    //slotUpdateInfo();

    // misc
    connect(_ui->monoIconsCheckBox, &QAbstractButton::toggled, this, &GeneralSettings::saveMiscSettings);
    connect(_ui->crashreporterCheckBox, &QAbstractButton::toggled, this, &GeneralSettings::saveMiscSettings);
    connect(_ui->newFolderLimitCheckBox, &QAbstractButton::toggled, this, &GeneralSettings::saveMiscSettings);
    connect(_ui->newFolderLimitSpinBox, static_cast<void (QSpinBox::*)(int)>(&QSpinBox::valueChanged), this, &GeneralSettings::saveMiscSettings);
    connect(_ui->newExternalStorage, &QAbstractButton::toggled, this, &GeneralSettings::saveMiscSettings);

#ifndef WITH_CRASHREPORTER
    _ui->crashreporterCheckBox->setVisible(false);
#endif

    // Hide on non-Windows, or WindowsVersion < 10.
    // The condition should match the default value of ConfigFile::showInExplorerNavigationPane.
#ifdef Q_OS_WIN
    #if QTLEGACY
        if (QSysInfo::windowsVersion() < QSysInfo::WV_WINDOWS10)
    #else
        if (QOperatingSystemVersion::current() < QOperatingSystemVersion::Windows10)
    #endif
            _ui->showInExplorerNavigationPaneCheckBox->setVisible(false);
#else
    // Hide on non-Windows
    _ui->showInExplorerNavigationPaneCheckBox->setVisible(false);
#endif

    /* Set the left contents margin of the layout to zero to make the checkboxes
     * align properly vertically , fixes bug #3758
     */
    int m0 = 0;
    int m1 = 0;
    int m2 = 0;
    int m3 = 0;
    _ui->horizontalLayout_3->getContentsMargins(&m0, &m1, &m2, &m3);
    _ui->horizontalLayout_3->setContentsMargins(0, m1, m2, m3);

    // OEM themes are not obliged to ship mono icons, so there
    // is no point in offering an option
    _ui->monoIconsCheckBox->setVisible(Theme::instance()->monoIconsAvailable());

    connect(_ui->ignoredFilesButton, &QAbstractButton::clicked, this, &GeneralSettings::slotIgnoreFilesEditor);

    // accountAdded means the wizard was finished and the wizard might change some options.
    connect(AccountManager::instance(), &AccountManager::accountAdded, this, &GeneralSettings::loadMiscSettings);

    customizeStyle();
}

GeneralSettings::~GeneralSettings()
{
    delete _ui;
    delete _syncLogDialog;
}

QSize GeneralSettings::sizeHint() const
{
    return {
        ownCloudGui::settingsDialogSize().width(),
        QWidget::sizeHint().height()
    };
}

void GeneralSettings::loadMiscSettings()
{
    QScopedValueRollback<bool> scope(_currentlyLoading, true);
    ConfigFile cfgFile;
    _ui->monoIconsCheckBox->setChecked(cfgFile.monoIcons());
    _ui->serverNotificationsCheckBox->setChecked(cfgFile.optionalServerNotifications());
    _ui->showInExplorerNavigationPaneCheckBox->setChecked(cfgFile.showInExplorerNavigationPane());
    _ui->crashreporterCheckBox->setChecked(cfgFile.crashReporter());
    auto newFolderLimit = cfgFile.newBigFolderSizeLimit();
    _ui->newFolderLimitCheckBox->setChecked(newFolderLimit.first);
    _ui->newFolderLimitSpinBox->setValue(newFolderLimit.second);
    _ui->newExternalStorage->setChecked(cfgFile.confirmExternalStorage());
    _ui->monoIconsCheckBox->setChecked(cfgFile.monoIcons());
    _ui->virtualFileSystemCheckbox->setChecked(cfgFile.enableVirtualFileSystem());
}

#if defined(BUILD_UPDATER)
void GeneralSettings::slotUpdateInfo()
{
    // Note: the sparkle-updater is not an OCUpdater
    auto *updater = qobject_cast<OCUpdater *>(Updater::instance());
    if (ConfigFile().skipUpdateCheck()) {
        updater = nullptr; // don't show update info if updates are disabled
    }

    if (updater) {
        connect(updater, &OCUpdater::downloadStateChanged, this, &GeneralSettings::slotUpdateInfo, Qt::UniqueConnection);
        connect(_ui->restartButton, &QAbstractButton::clicked, updater, &OCUpdater::slotStartInstaller, Qt::UniqueConnection);
        connect(_ui->restartButton, &QAbstractButton::clicked, qApp, &QApplication::quit, Qt::UniqueConnection);
        connect(_ui->updateButton, &QAbstractButton::clicked, this, &GeneralSettings::slotUpdateCheckNow, Qt::UniqueConnection);
        connect(_ui->autoCheckForUpdatesCheckBox, &QAbstractButton::toggled, this, &GeneralSettings::slotToggleAutoUpdateCheck);

        QString status = updater->statusString();
        Theme::replaceLinkColorStringBackgroundAware(status);
        _ui->updateStateLabel->setText(status);


        _ui->restartButton->setVisible(updater->downloadState() == OCUpdater::DownloadComplete);

        _ui->updateButton->setEnabled(updater->downloadState() != OCUpdater::CheckingServer &&
                                      updater->downloadState() != OCUpdater::Downloading &&
                                      updater->downloadState() != OCUpdater::DownloadComplete);

        _ui->autoCheckForUpdatesCheckBox->setChecked(ConfigFile().autoUpdateCheck());
    } else {
        // can't have those infos from sparkle currently
        _ui->updatesGroupBox->setVisible(false);
    }
}

void GeneralSettings::slotUpdateCheckNow()
{
    auto *updater = qobject_cast<OCUpdater *>(Updater::instance());
    if (ConfigFile().skipUpdateCheck()) {
        updater = nullptr; // don't show update info if updates are disabled
    }

    if (updater) {
        _ui->updateButton->setEnabled(false);

        updater->checkForUpdate();
    }
}

void GeneralSettings::slotToggleAutoUpdateCheck()
{
    ConfigFile cfgFile;
    bool isChecked = _ui->autoCheckForUpdatesCheckBox->isChecked();
    cfgFile.setAutoUpdateCheck(isChecked, QString());
}
#endif // defined(BUILD_UPDATER)

void GeneralSettings::saveMiscSettings()
{
    if (_currentlyLoading)
        return;
    ConfigFile cfgFile;
    bool isChecked = _ui->monoIconsCheckBox->isChecked();
    cfgFile.setMonoIcons(isChecked);
    Theme::instance()->setSystrayUseMonoIcons(isChecked);
    cfgFile.setCrashReporter(_ui->crashreporterCheckBox->isChecked());

    cfgFile.setNewBigFolderSizeLimit(_ui->newFolderLimitCheckBox->isChecked(),
        _ui->newFolderLimitSpinBox->value());
    cfgFile.setConfirmExternalStorage(_ui->newExternalStorage->isChecked());
}

void GeneralSettings::slotToggleLaunchOnStartup(bool enable)
{
    Theme *theme = Theme::instance();
    Utility::setLaunchOnStartup(theme->appName(), theme->appNameGUI(), enable);
}

void GeneralSettings::slotToggleOptionalServerNotifications(bool enable)
{
    ConfigFile cfgFile;
    cfgFile.setOptionalServerNotifications(enable);
}

void GeneralSettings::slotToggleOptionalVirtualFileSystem(bool enable)
{
    ConfigFile cfgFile;
    cfgFile.setEnableVirtualFileSystem(enable);

#if defined(Q_OS_MAC)
    if (enable) {
        QString defaultFileStreamSyncPath = cfgFile.defaultFileStreamSyncPath();
        QString defaultFileStreamMirrorPath = cfgFile.defaultFileStreamMirrorPath();

        if (defaultFileStreamSyncPath.isEmpty() || defaultFileStreamSyncPath.compare(QString("")) == 0)
            cfgFile.setDefaultFileStreamSyncPath(QString("/Volumes/" + Theme::instance()->appName() + "fs"));

        if (defaultFileStreamMirrorPath.isEmpty() || defaultFileStreamMirrorPath.compare(QString("")) == 0)
            cfgFile.setDefaultFileStreamMirrorPath(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/.cachedFiles");

        //FIXME this doesnt work for multiple accounts...
        for (const auto &ai : AccountManager::instance()->accounts()) {
            emit mountVirtualDrive(ai.data());
        }
    } else {
        VfsMac::instance()->unmount();
    }
#endif

#ifdef Q_OS_WIN
    if (enable) {
        //< Set configuration paths.
        QString m_defaultFileStreamSyncPath = cfgFile.defaultFileStreamSyncPath();
        QString m_defaultFileStreamMirrorPath = cfgFile.defaultFileStreamMirrorPath();
        QString m_defaultFileStreamLetterDrive = cfgFile.defaultFileStreamLetterDrive();
        QString availableLogicalDrive = VfsWindows::instance()->getAvailableLogicalDrive();

        if (m_defaultFileStreamSyncPath.isEmpty() || m_defaultFileStreamSyncPath.compare(QString("")) == 0)
            cfgFile.setDefaultFileStreamSyncPath(availableLogicalDrive + QString(":/")
                + Theme::instance()->appName());

        if (m_defaultFileStreamMirrorPath.isEmpty() || m_defaultFileStreamMirrorPath.compare(QString("")) == 0)
            cfgFile.setDefaultFileStreamMirrorPath(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/cachedFiles");

        if (m_defaultFileStreamLetterDrive.isEmpty() || m_defaultFileStreamLetterDrive.compare(QString("")) == 0)
            cfgFile.setDefaultFileStreamLetterDrive(availableLogicalDrive);

        //FIXME this doesnt work for multiple accounts...
        for (const auto &ai : AccountManager::instance()->accounts()) {
            emit mountVirtualDrive(ai.data());
        }
    } else {
        VfsWindows::instance()->unmount();
    }
#endif
}

void GeneralSettings::slotShowInExplorerNavigationPane(bool checked)
{
    ConfigFile cfgFile;
    cfgFile.setShowInExplorerNavigationPane(checked);
    // Now update the registry with the change.
    FolderMan::instance()->navigationPaneHelper().setShowInExplorerNavigationPane(checked);
}

void GeneralSettings::slotIgnoreFilesEditor()
{
    if (_ignoreEditor.isNull()) {
        ConfigFile cfgFile;
        _ignoreEditor = new IgnoreListEditor(this);
        _ignoreEditor->setAttribute(Qt::WA_DeleteOnClose, true);
        _ignoreEditor->open();
    } else {
        ownCloudGui::raiseDialog(_ignoreEditor);
    }
}

void GeneralSettings::slotShowLegalNotice()
{
    auto notice = new LegalNotice();
    notice->exec();
    delete notice;
}

void GeneralSettings::slotStyleChanged()
{
    customizeStyle();
}

void GeneralSettings::customizeStyle()
{
    // setup about section
    QString about = Theme::instance()->about();
    Theme::replaceLinkColorStringBackgroundAware(about);
    _ui->aboutLabel->setText(about);

#if defined(BUILD_UPDATER)
    // updater info
    slotUpdateInfo();
#else
    _ui->updatesGroupBox->setVisible(false);
#endif
}

} // namespace OCC
