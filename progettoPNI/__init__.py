# -*- coding: utf-8 -*-
"""
/***************************************************************************
 ProgettoPNI
                                 A QGIS plugin
 Gestione progetti PNI
                             -------------------
        begin                : 2019-01-01
        copyright            : (C) 2019 by A.R.Gaeta/Vertical Srl
        email                : ar_gaeta@yahoo.it
        git sha              : $Format:%H$
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 This script initializes the plugin, making it known to QGIS.
"""


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    """Load ProgettoPNI class from file ProgettoPNI.

    :param iface: A QGIS interface instance.
    :type iface: QgsInterface
    """
    #
    from .progetto_pni import ProgettoPNI
    return ProgettoPNI(iface)
