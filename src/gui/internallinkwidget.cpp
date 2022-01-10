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

#include "ui_internallinkwidget.h"
#include "internallinkwidget.h"
#include "account.h"
#include "capabilities.h"
#include "guiutility.h"
#include "sharemanager.h"
#include "theme.h"
#include "elidedlabel.h"

#include "QProgressIndicator.h"
#include <QBuffer>
#include <QClipboard>
#include <QFileInfo>
#include <QDesktopServices>
#include <QMessageBox>
#include <QMenu>
#include <QTextEdit>
#include <QToolButton>
#include <QPropertyAnimation>

namespace OCC {

Q_LOGGING_CATEGORY(lcInternalLink, "nextcloud.gui.internaklink", QtInfoMsg)

InternalLinkWidget::InternalLinkWidget(AccountPtr account,
    const QString &sharePath,
    const QString &localPath,
    QWidget *parent)
    : QWidget(parent)
    , _ui(new Ui::InternalLinkWidget)
    , _account(account)
    , _sharePath(sharePath)
    , _localPath(localPath)
{
    _ui->setupUi(this);

    //Is this a file or folder?
    QFileInfo fi(localPath);
    _isFile = fi.isFile();

    connect(_ui->copyInternalLinkButton, &QPushButton::clicked, this, &InternalLinkWidget::slotCopyInternalLink);

    _ui->errorLabel->hide();

    // check if the file is already inside of a synced folder
    if (sharePath.isEmpty()) {
        qCWarning(lcInternalLink) << "Unable to share files not in a sync folder.";
        return;
    }
}

InternalLinkWidget::~InternalLinkWidget()
{
    delete _ui;
}

void InternalLinkWidget::setupUiOptions()
{
    customizeStyle();
}

void InternalLinkWidget::slotCopyInternalLink(const bool clicked) const
{
    Q_UNUSED(clicked);

    //QApplication::clipboard()->setText(_linkInternal->getLink().toString());
}

void InternalLinkWidget::displayError(const QString &errMsg)
{
    _ui->errorLabel->setText(errMsg);
    _ui->errorLabel->show();
}

void InternalLinkWidget::slotStyleChanged()
{
    customizeStyle();
}

void InternalLinkWidget::customizeStyle()
{
    _ui->copyInternalLinkButton->setIcon(Theme::createColorAwareIcon(":/client/theme/copy.svg"));

    const auto externalIcon = Theme::createColorAwareIcon(":/client/theme/external.svg");
    _ui->internalLinkIconLabel->setPixmap(externalIcon.pixmap(externalIcon.actualSize(_ui->internalLinkIconLabel->size())));
}

}
