"""
Data Models
"""

from google.appengine.ext import db
import datetime, json

class BaseModel(db.Model):
    def toJSON(self):
        return {'id': str(self.key().id_or_name())}

    def __str__(self):
        return json.dumps(self.toJSON(), sort_keys=True, indent=4)
