"""
Data Models
"""

from google.appengine.ext import db
from google.appengine.ext import blobstore
import datetime, json

class BaseModel(db.Model):
    def __str__(self):
        return json.dumps(self.toJSON(), sort_keys=True, indent=4)

    def toJSON(self):
        return {'id': str(self.key().id_or_name())}
