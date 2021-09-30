import os

from qgis.PyQt import uic
from qgis.PyQt import QtWidgets


FORM2_CLASS, _ = uic.loadUiType(os.path.join(
    os.path.dirname(__file__), 'vista_resultados_dialog_base.ui'))


class ResultsDialog(QtWidgets.QDialog, FORM2_CLASS):
    def __init__(self, parent=None):
        """Constructor."""
        super(ResultsDialog, self).__init__(parent)
        # Set up the user interface from Designer through FORM_CLASS.
        # After self.setupUi() you can access any designer object by doing
        # self.<objectname>, and you can use autoconnect slots - see
        # http://qt-project.org/doc/qt-4.8/designer-using-a-ui-file.html
        # #widgets-and-dialogs-with-auto-connect
        self.setupUi(self)