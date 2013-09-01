# import yaml

# middleware_list = []

# with open("app.yaml") as f:
#   appyaml = yaml.load(f)
#   for include in appyaml.get("includes", []):
#     try:
#       module = __import__(include.replace("/", "."), globals(), locals(), ['Middleware'], -1)
#       middleware = getattr(module, 'Middleware', None)
#       if middleware:
#         middleware_list.append(middleware)
#     except ImportError:
#       pass


# # Loads any registered middleware, i.e. included modules that have a Middleware class
# def webapp_add_wsgi_middleware(app):
#   for middleware in middleware_list:
#     app = middleware(app)
#   return app
