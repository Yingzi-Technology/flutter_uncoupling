
# 背景
因为Flutter禁止了动态特性及反射，所以Flutter代码无法实现运行时解耦，只能在编译时解耦。基于这个背景，uncoupling提供了物理解耦的方案，因为基于dart实现的，所以不需要依赖第三方的运行环境。

# 原理
uncoupling使用了标记的方式，直接操作文件代码以实现代码物理方式的灵活插入与抽取，对工程没有任何侵入性，简单易用。

# 使用方式
将uncoupling目录拖入工程根目录（原则上适用于任何目录），示例请参考代码中的 demo 演示代码。

### 步骤1：在需要解耦的地方添加标记节点。
> ///@@[plugin.node]@begin  
> [your code]  
> ///@@[plugin.node]@end  

### 步骤2：在uncoupling/run.dart中配置标记节点及内容
> var _pluginNodeContent = {
>   "[plugin]" : {"[node]" : '''[content]'''}
> };
> 
如上所示步骤1和2，参数描述如下：  
[*plugin*]: 节点集合，如插件可以归类为一个集合并命名demo；  
[*node*]: 节点，用于标记代码块，每个代码块代表一个节点，如防非下某个任务跳转代码块 xxtask；  
[*content*]: 节点内容，带格式的代码块内容，用'''标记；    
  
  
### 步骤3：在uncoupling/run.dart中配置需要解耦的dart代码目录及配置文件
> const _dartRootDirectory = "./lib";  
> const _configPaths = [  
>   "./pubspec.yaml",  
>   "./config_plugin.sh"  
> ];  
> String _exportBizDirectory = "./uncoupling/biz";
  
变量描述如下：  
*_dartRootDirectory*: dart代码根目录，默认./lib  
*_configPaths*: 配置文件，如pubspec.yaml  
*_exportBizDirectory*：进行解耦操作时临时存取抽取的代码，方便步骤2批量操作，如步骤2已配置完整可以不用


### 步骤4：执行命令
**抽取全部命令**: cd <root directory>; dart uncoupling/run.dart -p demo -m clear  

**抽取部分命令**: cd <root directory>; dart uncoupling/run.dart -p demo -m add -n xxtask  

**插入（全部/部分）命令**: cd <root directory>; dart uncoupling/run.dart -p demo -m add  


> -p <plugin name>[demo] 插件名，如示例: demo   

> -m <method>[clear/add/del] 操作方法，如示例: clear；clear表示清除全部标记内容，add表示全部或部分标记内容，del表示删除部分标记内容 

> -d <rootDirectory>[default: ./lib] dart代码根目录  

> -n <node>[default: all, value such as: home,task,alarm] 节点内容，配合add和del部分标记内容使用  

> -e <export file>: export file that contains plugin contents, be effective to method clear and del. 临时导出clear或del操作时的节点内容  
