"""
Data Models
"""

from google.appengine.ext import ndb
import datetime, json

class BaseModel(ndb.Model):

    @property
    def id(self):
        return str(self.key.id())

    def toJSON(self):
        return {'id': self.id}

    def __str__(self):
        return json.dumps(self.toJSON(), sort_keys=True, indent=4)
