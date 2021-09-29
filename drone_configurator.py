from qgis.PyQt.QtCore import QSettings, QTranslator, QCoreApplication
from qgis.core import QgsProviderRegistry
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtWidgets import QAction
from qgis.utils import iface
from .resources import *
from .drone_configurator_dialog import DroneDialog
import os.path
import os

class Drone:
    

    def __init__(self, iface):
        """Constructor.

        :param iface: An interface instance that will be passed to this class
            which provides the hook by which you can manipulate the QGIS
            application at run time.
        :type iface: QgsInterface
        """
        # Save reference to the QGIS interface
        self.iface = iface
        # initialize plugin directory
        self.plugin_dir = os.path.dirname(__file__)
        # initialize locale
        self.settings = QSettings()

        self.pluginName = 'drone_configurator'

        locale = self.settings.value('locale/userLocale')[0:2]

        locale_path = os.path.join(
            self.plugin_dir,
            'i18n',
            'Drone_{}.qm'.format(locale))

        if os.path.exists(locale_path):
            self.translator = QTranslator()
            self.translator.load(locale_path)
            QCoreApplication.installTranslator(self.translator)

        # Declare instance attributes
        self.actions = []
        self.menu = self.tr(u'&Drone Configurator')
        # load 
        self.connection = self.getConnection()
        # Check if plugin was started the first time in current QGIS session
        # Must be set in initGui() to survive plugin reloads
        self.first_start = None
        
    def tr(self, message):
        """Get the translation for a string using Qt translation API.

        We implement this ourselves since we do not inherit QObject.

        :param message: String for translation.
        :type message: str, QString

        :returns: Translated version of message.
        :rtype: QString
        """

        return QCoreApplication.translate('Drone', message)

    def saveSetting(self,key,value):
        """ this save plugin settings """
        self.settings.setValue(self.pluginName+'/'+key,value)

    def loadSetting(self,key):
        """ this load plugin settings """
        return self.settings.value(self.pluginName+'/'+key)

    def add_action(
        self,
        icon_path,
        text,
        callback,
        enabled_flag=True,
        add_to_menu=True,
        add_to_toolbar=True,
        status_tip=None,
        whats_this=None,
        parent=None):
        """Add a toolbar icon to the toolbar.

        :param icon_path: Path to the icon for this action. Can be a resource
            path (e.g. ':/plugins/foo/bar.png') or a normal file system path.
        :type icon_path: str

        :param text: Text that should be shown in menu items for this action.
        :type text: str

        :param callback: Function to be called when the action is triggered.
        :type callback: function

        :param enabled_flag: A flag indicating if the action should be enabled
            by default. Defaults to True.
        :type enabled_flag: bool

        :param add_to_menu: Flag indicating whether the action should also
            be added to the menu. Defaults to True.
        :type add_to_menu: bool

        :param add_to_toolbar: Flag indicating whether the action should also
            be added to the toolbar. Defaults to True.
        :type add_to_toolbar: bool

        :param status_tip: Optional text to show in a popup when mouse pointer
            hovers over the action.
        :type status_tip: str

        :param parent: Parent widget for the new action. Defaults None.
        :type parent: QWidget

        :param whats_this: Optional text to show in the status bar when the
            mouse pointer hovers over the action.

        :returns: The action that was created. Note that the action is also
            added to self.actions list.
        :rtype: QAction
        """

        icon = QIcon(icon_path)
        action = QAction(icon, text, parent)
        action.triggered.connect(callback)
        action.setEnabled(enabled_flag)

        if status_tip is not None:
            action.setStatusTip(status_tip)

        if whats_this is not None:
            action.setWhatsThis(whats_this)

        if add_to_toolbar:
            # Adds plugin icon to Plugins toolbar
            self.iface.addToolBarIcon(action)

        if add_to_menu:
            self.iface.addPluginToMenu(
                self.menu,
                action)

        self.actions.append(action)

        return action

    def initGui(self):
        """Create the menu entries and toolbar icons inside the QGIS GUI."""

        icon_path = ':/plugins/drone_configurator/icon.png'
        self.add_action(
            icon_path,
            text=self.tr(u'Configurar Drone'),
            callback=self.run,
            parent=self.iface.mainWindow())

        # will be set False in run()
        self.first_start = True


    def unload(self):
        """Removes the plugin menu item and icon from QGIS GUI."""
        for action in self.actions:
            self.iface.removePluginMenu(
                self.tr(u'&Drone Configurator'),
                action)
            self.iface.removeToolBarIcon(action)

    def getSelectedArea(self):
        """ Get total area from one layer or the diference between current layer and other layeres """
        canvas = iface.mapCanvas()

        layers = canvas.layers()
        currentLayer = canvas.currentLayer()
        # get a geom from all features selectected in current layer
        geom1 = self.getGeomFromSelectedFeatures(currentLayer.selectedFeatures())
        
        # get a geom from all features selectected in anothers layers
        geom2 = None
        for layer in layers:
            if(layer != currentLayer):
                if(geom2 == None):
                    geom2 = self.getGeomFromSelectedFeatures(layer.selectedFeatures())
                else:
                    geom2.combine(self.getGeomFromSelectedFeatures(layer.selectedFeatures()))
        
        # there are not geoms selected in current layer
        if(geom1 == None):
            return 0

        # only select geoms from current layer
        if(geom2 == None):
            return geom1.area()

        # get diference between geom1(currentLayer) and geom2(other leyers)
        resultGeom = geom1.difference(geom2)
        
        return resultGeom.area()

    def getGeomFromSelectedFeatures(self,features):
        """ Get a single geom from features list"""
        geom = None
        for feat in features:
            if geom == None:
                geom = feat.geometry()
            else:
                geom = geom.combine(feat.geometry())
        return geom

    def getDatabases(self):
        """ Get list of database from QGIS """
        return QgsProviderRegistry.instance().providerMetadata('postgres').connections()
    
    def getConnection(self):
        """ 
            get connection from the last database used or the first in the list
        """
        lastConnection = self.loadSetting('database')
        connections = self.getDatabases()
        if(len(connections) > 0):
            if lastConnection: # se ha seleccionado previamente una base de datos
                for key in connections:
                    if key == lastConnection:
                        return connections[key]
            else:
                keys = list(connections.keys())
                connection = connections[keys[0]]
                self.saveSetting('database',keys[0])
                return connection
        return None

    def changeDrone(self,index):
        """ this function is called when the user select another drone """
        drone = self.drones[index]
        self.configurations = self.connection.execSql('select * from configuraciones where drone ='+ str(drone[0])).rows()
        # fill the combobox with configurations for the selected drone

    def changeDatabase(self,database):
        """ this function is called when the user select another database """
        # store the new database target
        self.saveSetting('database',database)
        # get new database connection
        self.connection = self.getConnection()
        # load basic data
        self.initData()


    def fillDBCombo(self):
        pass

    def initData(self):
        """ charge the basic data form database when is first screen load or the database target change """
        
        #Verify if the tables exist in the database
        existsDrones = self.connection.execSql("SELECT EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'drones');").rows()[0]
        existsProducts = self.connection.execSql("SELECT EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'configuraciones');").rows()[0]
        existsConfiguration = self.connection.execSql("SELECT EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'productos');").rows()[0]
        
        if existsDrones[0] and existsProducts[0] and existsConfiguration[0]:
            self.drones = self.connection.execSql('select * from drones').rows() 
            self.dlg.comboBoxDrone.activated.connect(self.changeDrone)

            for row in self.drones:
                self.dlg.comboBoxDrone.addItem(row[2],row[0])

    def run(self):
        """Run method that performs all the real work"""

        # Create the dialog with elements (after translation) and keep reference
        # Only create GUI ONCE in callback, so that it will only load when the plugin is started
        if self.first_start == True:
            self.first_start = False
            self.dlg = DroneDialog()
            self.databases = list(self.getDatabases().keys())
            for row in self.databases:
                self.dlg.comboBoxBaseDatos.addItem(row)
            self.dlg.comboBoxBaseDatos.activated.connect(self.changeDatabase)
            self.initData()

        area = self.getSelectedArea()

        # show the dialog
        self.dlg.show()

        # Run the dialog event loop
        result = self.dlg.exec_()
        # See if OK was pressed
        if result:
            # Do something useful here - delete the line containing pass and
            # substitute with your code.
            pass
