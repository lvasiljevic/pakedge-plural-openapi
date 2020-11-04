function parseURI(URI){
	return URI.match(/\/\w+/gi);
}

function parseURInew(URI){
	var res = URI.split('/').map(function(el){
		return "/"+el;
	});
	res.shift()
	return res;
}

function getResourceRecursive(ramlObj, searchURI){
	return ramlObj['resources'].map(function(el){
		if (el['relativeUri'] === searchURI[0]){
			searchURI = searchURI.splice(1);
			if (searchURI.length === 1){
				return el['resources'];
			}else{
				return getResourceRecursive(el, searchURI);
			}
		}
	}).reduce(function(acc, el){
		if (acc !== undefined){
			return acc
		}else if (el !== undefined) {
			return el;
		}
	});
}

function filterByRelativeURI(obj, searchURI){
	return obj.filter(function(el){
		if (el['relativeUri'] === searchURI){
			return el;
		}
	});
}

function getResource(ramlObj, searchURI){
	let lastURIPortion = searchURI.slice(-1);
	if (searchURI.length === 1){
		return filterByRelativeURI(ramlObj['resources'], lastURIPortion[0]);
	}
	return filterByRelativeURI(getResourceRecursive(ramlObj, searchURI), lastURIPortion[0]);
}

function getResponseCodeObj(arr, searchMethod, responseCode){
	return (arr.reduce(function(el){
		return el;
	})['methods'].map(function(el){
		if (el['method'] === searchMethod){
			return el['responses'];
		}
	}).reduce(function(acc, el){
		if (acc !== undefined){
			return acc;
		}else if (el !== undefined) {
			return el;
		}
	})[responseCode])
}

function getRequestObj(arr, searchMethod){
	return (arr.reduce(function(el){
			return el;
		})['methods'].map(function(el){
			if (el['method'] === searchMethod){
				return el;
			}
		})).reduce(function(acc, el){
			if (acc !== undefined){
				return acc;
			}else if (el !== undefined) {
				return el;
			}
		})
}

module.exports = {

	parseURI: parseURI,
	parseURInew: parseURInew,

	getResponseExample: function (ramlObj, searchURI, searchMethod, responseCode){
		return getResponseCodeObj(getResource(ramlObj, searchURI), searchMethod, responseCode)['body']['application/json']['example']
  	},

	getResponseSchema: function (ramlObj, searchURI, searchMethod, responseCode){
		return getResponseCodeObj(getResource(ramlObj, searchURI), searchMethod, responseCode)['body']['application/json']['schema']
  	},

	getRequestSchema: function (ramlObj, searchURI, searchMethod){
		return getRequestObj(getResource(ramlObj, searchURI), searchMethod)['body']['application/json']['schema'];
	},

	getRequestExample: function (ramlObj, searchURI, searchMethod){
		return getRequestObj(getResource(ramlObj, searchURI), searchMethod)['body']['application/json']['example'];
	}
}