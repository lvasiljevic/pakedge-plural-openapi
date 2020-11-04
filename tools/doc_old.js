const YAML = require('json-to-pretty-yaml');
const api = require('./apiWrapper');
const eol = require("eol");
const fs = require('fs')

const parseSchema = require('./parseRAMLSchema');

const argv = process.argv.slice(2);

const platform = argv[0];
const baseUri = 'https://192.168.1.1/api/v' + argv[1];
const env_endpoint = argv[2];
const method = argv[3];
const schema_router = argv[4];
const code = argv[5];

function deepRemove(obj, key) {
    for (var i in obj) {
        if (!obj.hasOwnProperty(i)) continue;
        if (typeof obj[i] == 'object') {
            obj[i] = deepRemove(obj[i], key);
        } else if (i == key) {
            delete obj[i];
        }
    }
    return obj;
}

function deepSearch(obj) {
	if (obj.hasOwnProperty('resources')){
		obj['resources'].map(function(el){
			console.log(el);
			deepSearch(el);
		})
	}
}

function getResourceRecursive(ramlObj){
	return ramlObj['resources'].map(function(el){
		console.log(el);
		return getResourceRecursive(el);
	})
}

const path = '../pakedge-plural/tools/node_modules/' + platform.toLowerCase() + '-plural-v' +  argv[1];

try {
	if (fs.existsSync(path)) {
		api.createAPI(platform, {baseUri: baseUri}).then(function(clients){
			if (schema_router == 'req'){
				let schema = JSON.parse(parseSchema.getRequestSchema(clients[0]['ramlObj'], parseSchema.parseURInew(env_endpoint), method));
				schema = deepRemove(schema, '$schema');
				console.log(YAML.stringify(schema));

				console.log("example:")
				schema = JSON.parse(parseSchema.getRequestExample(clients[0]['ramlObj'], parseSchema.parseURInew(env_endpoint), method));
				schema = deepRemove(schema, '$schema');
				let example_yaml = YAML.stringify(schema);
				let lines = eol.split(example_yaml);
				lines.forEach(function(line) {
					console.log("  ",line);
				});
				
			} else if (schema_router == 'res'){

				let schema = JSON.parse(parseSchema.getResponseSchema(clients[0]['ramlObj'], parseSchema.parseURInew(env_endpoint), method, code));
				schema = deepRemove(schema, '$schema');
				console.log(YAML.stringify(schema));

				console.log("example:")
				schema = JSON.parse(parseSchema.getResponseExample(clients[0]['ramlObj'], parseSchema.parseURInew(env_endpoint), method, code));
				schema = deepRemove(schema, '$schema');
				let example_yaml = YAML.stringify(schema);
				let lines = eol.split(example_yaml);
				lines.forEach(function(line) {
					console.log("  ",line);
				});
			}		
		});
	}
}catch(err) {
 	return
}

/*
clients[0].methodObjFilter(method, function(endpoint){
	if(endpoint.path == env_endpoint){
		if(schema_router == 'post-req'){

			let schema = JSON.parse(endpoint.getPOSTRequestSchema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getPOSTRequestExample());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'post-res-200'){
			let schema = JSON.parse(endpoint.getPOSTResponse200Schema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getPOSTResponse200Example());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'post-res-400'){
			let schema = JSON.parse(endpoint.getPOSTResponse400Schema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getPOSTResponse400Example());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'put-req'){
			let schema = JSON.parse(endpoint.getPUTRequestSchema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getPUTRequestExample());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'put-res-200'){
			let schema = JSON.parse(endpoint.getPUTResponse200Schema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getPUTResponse200Example());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'put-res-400'){
			let schema = JSON.parse(endpoint.getPUTResponse400Schema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getPUTResponse400Example());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'delete-res-200'){
			let schema = JSON.parse(endpoint.getDELETEResponse200Schema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getDELETEResponse200Example());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		} else if (schema_router == 'delete-res-400'){
			console.log("TESTs")
			let schema = JSON.parse(endpoint.getDELETEResponse400Schema());
			schema = deepRemove(schema, '$schema');
			console.log(YAML.stringify(schema));

			console.log("example:")
			schema = JSON.parse(endpoint.getDELETEResponse400Example());
			schema = deepRemove(schema, '$schema');
			let example_yaml = YAML.stringify(schema);
			let lines = eol.split(example_yaml);
			lines.forEach(function(line) {
				console.log("  ",line);
			});
		}
	} 	
});
*/