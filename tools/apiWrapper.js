const parseSchema = require('./parseRAMLSchema');
const raml        = require('raml-parser');

const Ajv         = require('ajv');
var  ajv          = new Ajv({schemaId: 'auto'});
ajv.addMetaSchema(require('ajv/lib/refs/json-schema-draft-04.json'));

//Helper
function objIttr(args, callback){
	for (var key in this){
		if (this[key]['path'] !== undefined && key !== 'client'){
			callback(this[key], args);
		}
		if (typeof this[key] == "object" && this[key] !== null && key !== 'client'){
			if (typeof this.objIttr == "function"){
				this.objIttr.call(this[key], args, callback);
			}
			else if (this.client !== undefined && typeof this.client.objIttr == "function"){
				this.client.objIttr.call(this[key], args, callback);
			}
		}
	}
}

function methodObjFilter(method, callback){
	this.objIttr({}, function(key, args){
		if (key[method] !== undefined){
			callback(key)
		}
	});
}

//Local
function getGETResponse200Example (){
	// return 666
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'get', '200');
}

function getPOSTResponse200Example (){
	console.log(parseSchema.parseURI(this['path']), this['path'])
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'post', '200');
}

function getPOSTResponse400Example (){
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'post', '400');
}

function getPUTResponse200Example (){
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'put', '200');
}

function getPUTResponse400Example (){
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'put', '400');
}

function getDELETEResponse200Example (){
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'delete', '200');
}

function getDELETEResponse400Example (){
	return parseSchema.getResponseExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'delete', '400');
}

function getDELETEResponse200Schema (){
	return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'delete', '200');
}

function getDELETEResponse400Schema (){
    return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'delete', '400');
}

function getGETResponse200Schema (){
	return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'get', '200');
}

function getGETResponse400Schema (){
    return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'get', '400');
}

function getPOSTRequestSchema (){
	return parseSchema.getRequestSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'post');
}

function getPOSTRequestExample (){
	return parseSchema.getRequestExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'post');
}

function getPOSTResponse200Schema (){
	return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'post', 200);
}

function getPOSTResponse400Schema (){
    return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'post', 400);
}

function getPUTRequestSchema (){
	return parseSchema.getRequestSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'put');
}

function getPUTRequestExample (){
	return parseSchema.getRequestExample(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'put');
}

function getPUTResponse200Schema (){
	return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'put', 200);
}

function getPUTResponse400Schema (){
    return parseSchema.getResponseSchema(this['client']['ramlObj'], parseSchema.parseURI(this['path']), 'put', 400);
}

function validateExample (example, schema){
	let validate = ajv.compile(schema);
	return {"valid": validate(example), "errors": validate.errors};
}

function getApiVersion (baseUri){
	return baseUri.match(/([^/]+)$/)[1];
}
function authApiUri(baseUri){
	return baseUri.replace(/([^/]+)$/,"v1");
}
//API
module.exports = {
  	createAPI: function (platform, baseURIObj){

  		let apiVersion = getApiVersion(baseURIObj.baseUri);

  		var API = require('../../pakedge-plural/tools/node_modules/' + platform.toLowerCase() + '-plural-' + apiVersion);
		const flatRAMLPath = '../pakedge-plural/doc/' + apiVersion + '/bin/' + platform + '_pluralAPI-flat.raml';

  		API.prototype.objIttr = objIttr;
  		API.prototype.getApiVersion = getApiVersion;
  		API.prototype.methodObjFilter = methodObjFilter;
  		//instantiate client
		let client = new API(baseURIObj);

  		//auth API
  		var API2 = require('../../pakedge-plural/tools/node_modules/' + platform.toLowerCase() + '-plural-v1');
		const flatRAMLPath2 = '../pakedge-plural/doc/v1/bin/' + platform + '_pluralAPI-flat.raml';
  		API2.prototype.objIttr = objIttr;
  		API2.prototype.getApiVersion = getApiVersion;
  		API2.prototype.methodObjFilter = methodObjFilter;
		let auth_client = new API2({baseUri: authApiUri(baseURIObj.baseUri)});
		//console.log(auth_client);
		//console.log(raml.loadFile(flatRAMLPath2))

		return raml.loadFile(flatRAMLPath2).then(function(data){
			//console.log(data);
			//add raml object
			auth_client.ramlObj = data;
			auth_client.objIttr([getGETResponse200Schema, getPOSTRequestSchema, getPOSTRequestExample, getPOSTResponse200Schema,getPOSTResponse400Schema, getGETResponse200Example], function(key, args){
				if (key['path'] !== undefined){

					//add methods for retrieving schemas and validation
					args.forEach(function(el){
						key[el['name']]={};
						key[el.name] = el;
					});

					//add validate method
					key['validate'] = validateExample;

				}
			});
			auth_client.options.apiVersion = "v1";

			return raml.loadFile(flatRAMLPath).then(function(data){
				//console.log(data);
				client.ramlObj = data;
				client.objIttr([getGETResponse200Schema,
				 getPOSTResponse200Example,
				 getPOSTResponse400Example,
				 getPUTResponse200Example,
				 getPUTResponse400Example,
				 getPOSTRequestSchema,
				 getPOSTRequestExample,
				 getPOSTResponse200Schema,
				 getPOSTResponse400Schema,
				 getGETResponse200Example,
				 getPUTRequestSchema,
				 getPUTResponse200Schema,
				 getPUTResponse400Schema,
				 getDELETEResponse200Schema,
				 getDELETEResponse400Schema,
				 getDELETEResponse200Example,
				 getDELETEResponse400Example,
				 getPUTRequestExample]
				 , function(key, args){
					if (key['path'] !== undefined){

						//add methods for retrieving schemas and validation
						args.forEach(function(el){
							key[el['name']]={};
							key[el.name] = el;
						});

						//add validate method
						key['validate'] = validateExample;

					}
				});
				client.options.apiVersion = getApiVersion(baseURIObj.baseUri);
				return [client,auth_client];
			});
		});
	}
};
