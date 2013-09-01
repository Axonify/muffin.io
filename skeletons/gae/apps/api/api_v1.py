#!/usr/bin/env python

import fix_path
import webapp2 as webapp
from apps.decorators import *
from apps.models import *
from apps import DEBUG
import json, re, logging, datetime

#
# Router
#
routes = []
app = webapp.WSGIApplication(routes, debug=DEBUG)
