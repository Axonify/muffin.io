#!/usr/bin/env python

import fix_path
import webapp2 as webapp
from apps.decorators import *
from apps.models import *
from apps import DEBUG
import json, re, logging

# GET /api/v1/
class MainHandler(webapp.RequestHandler):
    def get(self):
        self.response.out.write('OK')

#
# Router
#
baseUrl = '/api/v1'
routes = [
    (r'^%s/$' % baseUrl, MainHandler),
]
app = webapp.WSGIApplication(routes, debug=DEBUG)
