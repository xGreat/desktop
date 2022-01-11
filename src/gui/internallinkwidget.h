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

#ifndef INTERNALLINKWIDGET_H
#define INTERNALLINKWIDGET_H

#include "QProgressIndicator.h"
#include <QList>
#include <QToolButton>

namespace OCC {

namespace Ui {
    class InternalLinkWidget;
}

/**
 * @brief The ShareDialog class
 * @ingroup gui
 */
class InternalLinkWidget : public QWidget
{
    Q_OBJECT

public:
    explicit InternalLinkWidget(const QString &localPath,
        QWidget *parent = nullptr);
    ~InternalLinkWidget() override;

    void setupUiOptions();

private slots:
    void slotLinkFetched(const QString &url);
    void slotCopyInternalLink(const bool clicked) const;

private:
    void customizeStyle();

    Ui::InternalLinkWidget *_ui;
    QString _localPath;
    QString _internalUrl;

    QPushButton *_copyInternalLinkButton{};
};
}

#endif // INTERNALLINKWIDGET_H
