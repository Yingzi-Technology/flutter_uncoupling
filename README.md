
# 背景
因为Flutter禁止了动态特性及反射，所以Flutter代码无法实现运行时分离。基于这个背景，uncoupling提供了物理分离的方案，因为基于dart实现的，所以不需要依赖第三方的运行环境。

# 应用场景
- 当想写死部分测试代码供开发或测试临时使用，又要避免上线时把这些代码带到包里去的时候，可以使用这种方式；
- 当想打出来的包想临时或永久分离掉其它业务线的干扰代码时，每次人工分离太烦琐也容易出错，可以使用这种方式；
- 任何时间不同业务团队的开发、测试人员共用同一分支代码时可以通过配置编译出不同内容的包；
- 总之，根据配置项自动动态改变工程代码，避免人为出错，编译出不同的包。

# 原理
uncoupling使用了标记的方式，直接操作文件代码以实现代码物理方式的灵活插入与抽取，对工程没有任何侵入性，简单易用。

# 使用方式
将uncoupling目录拖入工程根目录（原则上适用于任何目录），示例请参考代码中的 demo 演示代码。

### 步骤1：在需要分离的地方添加标记节点，不同内容的节点名node不能相同。
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
  
  
### 步骤3：在uncoupling/run.dart中配置需要分离的dart代码目录及配置文件
> const _dartRootDirectory = "./lib";  
> const _configPaths = [  
>   "./pubspec.yaml",  
>   "./config_plugin.sh"  
> ];  
> String _exportBizDirectory = "./uncoupling/biz";
  
变量描述如下：  
*_dartRootDirectory*: dart代码根目录，默认./lib  
*_configPaths*: 配置文件，如pubspec.yaml  
*_exportBizDirectory*：进行分离操作时临时存取抽取的代码，方便步骤2批量操作，如步骤2已配置完整可以不用


### 步骤4：执行命令
**抽取全部命令**: cd <root directory>; dart uncoupling/run.dart -p demo -m clear  

**抽取部分命令**: cd <root directory>; dart uncoupling/run.dart -p demo -m add -n xxtask  

**插入（全部/部分）命令**: cd <root directory>; dart uncoupling/run.dart -p demo -m add  


> -p <plugin name>[demo] 插件名，如示例: demo   

> -m <method>[clear/add/del] 操作方法，如示例: clear；clear表示清除全部标记内容，add表示全部或部分标记内容，del表示删除部分标记内容 

> -d <rootDirectory>[default: ./lib] dart代码根目录  

> -n <node>[default: all, value such as: home,task,alarm] 节点内容，配合add和del部分标记内容使用  

> -e <export file>: export file that contains plugin contents, be effective to method clear and del. 临时导出clear或del操作时的节点内容  
