const fs = require('fs');
const mergeYaml = require('merge-yaml-cli');

function writeFl(fl, data){
	fs.writeFile(fl, data, function (err) {
	 	if (err) return console.log(err);
	});
}

var inputArgs = process.argv.slice(2);
var platforms = inputArgs[2].split(' ');
var fl_sufix=""

for(var i=0;i<platforms.length;i++){
	if(i == 0){
		fl_sufix = fl_sufix + platforms[i]
	}else{
		fl_sufix = fl_sufix + "_" + platforms[i]
	}
	platforms[i] = "bin/" + platforms[i] + "_" + inputArgs[1] + ".yaml"
}


const result = mergeYaml.merge(platforms);
writeFl("bin/" + fl_sufix + "_" + inputArgs[1] + ".yaml", result);
console.log(fl_sufix);