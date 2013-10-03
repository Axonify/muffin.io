mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

<$- classified $>Schema = new Schema<$ _(attrs).each(function(value, key, list)  { if (value === 'String') { $>
  <$- key $>: String<$ } else if (value === 'Number') { $>
  <$- key $>: Number<$ } else if (value === 'Date') { $>
  <$- key $>: Date<$ } else if (value === 'Buffer') { $>
  <$- key $>: Buffer<$ } else if (value === 'Boolean') { $>
  <$- key $>: Boolean<$ } else if (value === 'Mixed') { $>
  <$- key $>: Mixed<$ } else if (value === 'ObjectId') { $>
  <$- key $>: ObjectId<$ } else if (value === 'Array') { $>
  <$- key $>: Array<$ }}); $>
  created_at: { type: Date, default: Date.now }
  updated_at: Date

<$- classified $> = mongoose.model('<$- classified $>', <$- classified $>Schema)
module.exports = <$- classified $>
