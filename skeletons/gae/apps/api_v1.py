#!/usr/bin/env python

import fix_path
import webapp2 as webapp
from apps.decorators import *
from apps.models import *
from apps import DEBUG
import json, re, logging, datetime

# GET /api
class MainHandler(webapp.RequestHandler):
    def get(self):
        self.response.out.write('OK')

#
# Router
#
routes = [
    (r'/api', MainHandler),
]
app = webapp.WSGIApplication(routes, debug=DEBUG)
