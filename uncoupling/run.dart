/* 
 * @Author: yz.yujingzhou 
 * @Date: 2021-07-30 15:14:36 
 * @Last Modified by: yz.yujingzhou
 * @Last Modified time: 2021-07-30 15:43:15
 * @Describe: 描述：Flutter工程抽壳方案，从物理上使两个交叉引用的工程相互抽离，同时支持抽离后的工程重新合并
 */

import 'dart:convert';
import "dart:io";

part 'biz/demo.dart';

///插件节点内容<plugin, node content>
var _pluginNodeContent = {
  "demo" : demo
};

Map _duplicatedNodes = {}; //用来记录是否有重复的节点
Map _nodeContents = {}; //有来记录清除后的节点内容
const _dartRootDirectory = "./lib";
const _configPaths = [
  "./pubspec.yaml"
];
String _exportBizDirectory = "./uncoupling/biz";

/* Add node to the code around: 

///@@[plugin.node]@begin
///node content
///@@[plugin.node]@end 

or pubspec.yaml

#@@[plugin.node]@begin
#node content
#@@[plugin.node]@end 

Usage: cd <root directory>; dart uncoupling/run.dart -p demo -m clear
-p <plugin name>[aaa/demo] 插件名，如示例: demo
-m <method>[clear/add/del] 操作方法，如示例: clear；clear表示清除全部标记内容，add表示全部或部分标记内容，del表示删除部分标记内容
-d <rootDirectory>[default: ./lib] dart代码根目录
-n <node>[default: all, value such as: home,task,alarm] 节点内容，配合add和del部分标记内容使用
-e <export file>: export file that contains plugin contents, be effective to method clear and del. 临时导出clear或del操作时的节点内容
**/
void main(List<String> arguments) {
  UncoupingArg args = UncoupingArg();
  print(arguments);
  for (var i = 0; i < arguments.length; i += 2) {
    if (arguments[i] == '-p') {
      args.plugin = arguments[i + 1];
    } else if (arguments[i] == '-m') {
      args.method = arguments[i + 1];
    } else if (arguments[i] == '-d') {
      args.rootDirectory = arguments[i + 1];
    } else if (arguments[i] == '-n') {
      String _nodes = arguments[i + 1];
      if (_nodes != null && _nodes.isNotEmpty) {
        args.nodes = Map.fromIterable(_nodes.split(','), key: (e) => e, value: (e) => true,);        
      }
    } else if (arguments[i] == '-e') {
      if (i + 1 < arguments.length) {
        _exportBizDirectory = arguments[i + 1];
      }
      args.export = _exportBizDirectory;     
    }
  }

  _duplicatedNodes.clear();
  uncoupling(args.rootDirectory ?? _dartRootDirectory, args.plugin, args.method, args.nodes);
  _configPaths.forEach((path) { 
    uncouplingConfig(path, args.plugin, args.method, args.nodes);
  });
  
  if (args.export != null && args.method == 'clear') {
    exportTempFile(args.plugin);
  }   
}

void uncoupling(String rootPath, String plugin, String method, Map nodes){
  try{    
    var directory = new Directory(rootPath);
    List<FileSystemEntity> files = directory.listSync();
    for(var f in files){      
      var isFile = FileSystemEntity.isFileSync(f.path);
      if(!isFile){
        uncoupling(f.path, plugin, method, nodes);               
      } else { 
        if (!f.path.contains('.dart')) continue; //be effective to dart file       
        if (method == 'add') {
          add(f.path, plugin, nodes);
        } else if (method == 'clear') {
          clear(f.path, plugin);
        } else if (method == 'del') {
          del(f.path, plugin, nodes);
        }        
      } 
    }
  }catch(e){
      print("Error！${e.toString()}");
  } 

}

///添加插件代码
///@@[plugin.node]@begin
///node content
///@@[plugin.node]@end 
void add(String filePath, String plugin, Map nodes, [String anno = '///']) {

  File _f = File(filePath);
  var contents =  _f.readAsStringSync();
  RegExp exp = RegExp(matchPattern(plugin, anno: anno));
  if (nodes?.isEmpty ?? true) {
    
    contents = contents.replaceAllMapped(exp, (match){
      validateNodeDuplicated(match, filePath);
      return contentHolder(match, plugin, anno);
    });  

  } else {
    Iterable<Match> matchs = exp.allMatches(contents);  

    if (matchs != null && matchs.isNotEmpty) {          
      for (var match in matchs) {
        String _node = match[1];
        if (nodes[_node] == true) {
          validateNodeDuplicated(match, filePath); 
          contents = contents.replaceAll(RegExp(matchPattern(plugin, node: _node, anno: anno)), contentHolder(match, plugin, anno));
        }
      }      
    } 
  } 
  _f.writeAsString(contents);

}

///删除插件某些节点代码
///@@[plugin.node]@begin
///@@[plugin.node]@end 
void del(String filePath, String plugin, Map nodes, [String anno = '///']) {

  File _f = File(filePath);
  var contents =  _f.readAsStringSync();
  RegExp exp = RegExp(matchPattern(plugin, anno: anno));  
  Iterable<Match> matchs = exp.allMatches(contents);    
  if (nodes?.isEmpty ?? true) return;

  if (matchs != null && matchs.isNotEmpty) {          
    for (var match in matchs) {
      String _node = match[1];
      if (nodes[_node] == true) {
        validateNodeDuplicated(match, filePath);
        storeClearContent(match[1], match[2]);  
        contents = contents.replaceAll(RegExp(matchPattern(plugin, node: _node, anno: anno)), placeHolder(match, plugin, anno));
      }
    }      
  } 
  _f.writeAsString(contents);  

}

///清除插件代码
///@@[plugin.node]@begin
///@@[plugin.node]@end 
void clear(String filePath, String plugin, [String anno = '///']) {

  File _f = File(filePath);
  var contents =  _f.readAsStringSync();
  RegExp exp = RegExp(matchPattern(plugin, anno: anno));  
  contents = contents.replaceAllMapped(exp, (match){
    validateNodeDuplicated(match, filePath);
    storeClearContent(match[1], match[2]);  
    return placeHolder(match, plugin, anno);
  });  
  _f.writeAsString(contents);  

}

//判断节点是否有重复
void validateNodeDuplicated(Match match, String filePath) {
    if (_duplicatedNodes[match[1]] != null) {
      print("Warning: The node \"${match[1]}\" is duplicated!  Duplicated path is: $filePath and ${_duplicatedNodes[match[1]]}"); 
    }
    _duplicatedNodes[match[1]] = filePath;
}

String matchPattern(String plugin, {String node, String anno = '///'}) {
  if (node == null) {
    return anno + r"@@\[" + plugin + r"\.(.*)\]@begin([\s\S]+?)" + anno + r"@@\[" + plugin + r"\.(.*)\]@end";
  } else {
    return anno + r"@@\[" + plugin + r"\."+ node +r"\]@begin([\s\S]+?)" + anno + r"@@\[" + plugin + r"\."+ node +r"\]@end";    
  }
}

///填充的插件内容
String contentHolder(Match match, String plugin, [String anno = '///']) {
    return '''
$anno@@[$plugin.${match[1]}]@begin
${_pluginNodeContent[plugin][match[1]]}$anno@@[$plugin.${match[3]}]@end ''';
}

///插件内容占位符
String placeHolder(Match match, String plugin, [String anno = '///']) {
    return '''
$anno@@[$plugin.${match[1]}]@begin
$anno@@[$plugin.${match[3]}]@end ''';
}

///保存清除时抽取的内容
void storeClearContent(String node, String content) {
  _nodeContents[node] = content;
}

///输出临时存储插件节点及内空的文件
void exportTempFile(String plugin) async{
  String ts = DateTime.now().toString();
  var file = await File("$_exportBizDirectory/${plugin}_$ts.dart").create();
  file.writeAsString("Map $plugin=" + json.encode(_nodeContents) + ";");
}

class UncoupingArg {
  String plugin;
  String method;
  String rootDirectory;
  String export;
  Map<String, bool> nodes;

  UncoupingArg();
}

///------------uncoupling pubspec.yaml because of # or ///---------------///
void uncouplingConfig(String configPath, String plugin, String method, Map nodes){
  try{   

    if (method == 'add') {

      add(configPath, plugin, nodes, '#');                    

    } else if (method == 'clear') {
      
      clear(configPath, plugin, '#'); 

    } else if (method == 'del') {
       
      del(configPath, plugin, nodes, '#');

    }  

  }catch(e){
      print("Error！${e.toString()}");
  }
}