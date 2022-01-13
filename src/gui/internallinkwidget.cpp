/*
 * Copyright (C) 2022 by Claudio Cambra <claudio.cambra@nextcloud.com>
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

#include "internallinkwidget.h"
#include "accountstate.h"
#include "folderman.h"
#include "theme.h"

#include "QProgressIndicator.h"
#include <QClipboard>

namespace OCC {

Q_LOGGING_CATEGORY(lcInternalLink, "nextcloud.gui.internalink", QtInfoMsg)

InternalLinkWidget::InternalLinkWidget(const QString &localPath,
    QWidget *parent)
    : QWidget(parent)
    , _ui(new Ui::InternalLinkWidget)
    , _localPath(localPath)
{
    _ui->setupUi(this);

    const auto folder = FolderMan::instance()->folderForPath(_localPath);
    const auto folderRelativePath = _localPath.mid(folder->cleanPath().length() + 1);
    const auto serverRelativePath = QDir(folder->remotePath()).filePath(folderRelativePath);

    const auto bindLinkSlot = std::bind(&InternalLinkWidget::slotLinkFetched, this, std::placeholders::_1);

    fetchPrivateLinkUrl(
        folder->accountState()->account(),
        serverRelativePath,
        {},
        this,
        bindLinkSlot);

    _ui->copyInternalLinkButton->setEnabled(false);
    _ui->internalLinkProgressIndicator->setVisible(true);
    _ui->internalLinkProgressIndicator->startAnimation();

    connect(_ui->copyInternalLinkButton, &QPushButton::clicked, this, &InternalLinkWidget::slotCopyInternalLink);
}

void InternalLinkWidget::slotLinkFetched(const QString &url)
{
    _internalUrl = url;
    _ui->copyInternalLinkButton->setEnabled(true);
    _ui->internalLinkProgressIndicator->setVisible(false);
    _ui->internalLinkProgressIndicator->stopAnimation();
}

void InternalLinkWidget::slotCopyInternalLink() const
{
    QApplication::clipboard()->setText(_internalUrl);
}

}
