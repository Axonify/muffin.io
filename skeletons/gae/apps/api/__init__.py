#
# api
#

import webapp2 as webapp
from apps import DEBUG

class MainHandler(webapp.RequestHandler):
    def get(self):
        self.response.out.write('OK')

#
# Application
#
app = webapp.WSGIApplication([(r'/api', MainHandler)], debug=DEBUG)
