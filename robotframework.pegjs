{
// https://github.com/robotframework/robotframework/blob/14568e746c710c43f79a4d954dba042867d4b4e5/doc/userguide/src/CreatingTestData/TestDataSyntax.rst#plain-text-format


function _filterOutTypes(types=[]){
  return (matches)=>{
    console.log('filterouttypes', types, matches)
    return matches.filter(match => (!match || !types.includes(match.type)));
  }
}

let filterBlankLines = _filterOutTypes(['BlankLine']);
let filterComments = _filterOutTypes(['Comment']);
let filterBlankLinesAndComments = _filterOutTypes(['Comment', 'BlankLine']);
let filterTabs = _filterOutTypes(['Tab']);



}

Start
  = out:(
      Comment
    / BlankLine
    / Section
    )*
    EOF {
      return filterBlankLines(out);
    }



_ = [ \t]*
__ = [ \t]+

LF = "\r"? "\n"

EOL = _ (SingleLineComment / LF / EOF)


EOF
  = !. {
    return {
      type: 'EOF',
      location: location(),
    }
  }

Comment
  = comments:SingleLineComment+ {
    if(comments.length === 1){
      return comments[0];
    }

    let combined_comments = comments.map(function(comment_obj){
      return comment_obj.text;
    }).join("\n");

    return {
      type: 'Comment',
      text: combined_comments,
    };
  }

NotLF
  = !LF . { return text(); }

SingleLineComment
  = _ '#' [ \t]? comment:(NotLF)* EOL {
    return {
      type: 'Comment',
      text: comment.join(''),
    };
  }

BlankLine = _ LF {
    return {
      type: 'BlankLine',
      value: text(),
    };
  }

Section
  = "*"+ _
    section:(
      SettingsSection
    / VariablesSection
    / TestcasesSection
    / KeywordsSection
    ) {
      return section;
    }

SectionStarter
  = "*"+ _

SettingsSectionHeader = "setting"i "s"i? _ "*"* EOL
VariablesSectionHeader = "variable"i "s"i? _ "*"* EOL
TestcasesSectionHeader = "test"i _ "case"i "s"i? _ "*"* EOL
KeywordsSectionHeader = "keyword"i "s"i? _ "*"* EOL

SettingsSection =
  SettingsSectionHeader
  settings:(BlankLine / Comment / SettingDefinition / CatchLine)* {
    return {
      type: 'SettingsSection',
      settings: filterBlankLinesAndComments(settings),
    };
  }

CatchLine = !"*" str:(!LF c:Character {return c;} )+ EOL {
  return {
    type: 'CatchLine',
    text: str.join(''),
  }
}

SettingDefinition
  = setting_type:Value
    args:(Tab i:Value { return i })*
    Comment?
    EOL {
      return {
        type: 'SettingDefinition',
        setting_type: setting_type,
        args: args,
      }
    }

VariablesSection =
  VariablesSectionHeader
  variables:(BlankLine / Comment / VariableDefinition / CatchLine)* {
    return {
      type: 'VariablesSection',
      variables: filterBlankLinesAndComments(variables),
    };
  }

VariableDefinition
  = ScalarVariableDefinition
  / ListVariableDefinition
  / DictVariableDefinition

ScalarVariableDefinition
  = "${" name:AlphaNumUnderscoreSpaceString "}" ( Tab / _ "=" _ ) value:Value EOL {
    return {
      type: 'ScalarVariableDefinition',
      name: name,
      value: value,
    }
  }

ListVariableDefinition
  = "@{" name:AlphaNumUnderscoreSpaceString "}" (Tab / _ "=" _) head:Value tail:(Tab v:Value {return v})* EOL {
    return {
      type: 'ListVariableDefinition',
      name: name,
      value: [head, ...tail],
    }
  }

DictVariableDefinition
  = "&{" name:AlphaNumUnderscoreSpaceString "}" (Tab / _ "=" ) _ head:DictValue tail:(Tab v:DictValue {return v})* EOL {
    let obj = {
      [head.key.value]: head.value.value,
    };
    for(let i = 0; i < tail.length; i+=1){
      obj[tail[i].key.value] = tail[i].value.value;
    }

    return {
      type: 'DictVariableDefinition',
      name: name,
      value: obj,
    }
  }



VariableDefinitionNoTab
  = ScalarVariableDefinitionNoTab
  / ListVariableDefinitionNoTab
  / DictVariableDefinitionNoTab

ScalarVariableDefinitionNoTab
  = "${" name:AlphaNumUnderscoreSpaceString "}" _ "=" _ value:Value EOL {
    return {
      type: 'ScalarVariableDefinition',
      name: name,
      value: value,
    }
  }

ListVariableDefinitionNoTab
  = "@{" name:AlphaNumUnderscoreSpaceString "}" _ "=" _ head:Value tail:(Tab v:Value {return v})* EOL {
    return {
      type: 'ListVariableDefinition',
      name: name,
      value: [head, ...tail],
    }
  }

DictVariableDefinitionNoTab
  = "&{" name:AlphaNumUnderscoreSpaceString "}" _ "=" _ head:DictValue tail:(Tab v:DictValue {return v})* EOL {
    let obj = {
      [head.key.value]: head.value.value,
    };
    for(let i = 0; i < tail.length; i+=1){
      obj[tail[i].key.value] = tail[i].value.value;
    }

    return {
      type: 'DictVariableDefinition',
      name: name,
      value: obj,
    }
  }

KeywordsSection =
  KeywordsSectionHeader
  keywords:(BlankLine / Comment / KeywordDefinition / CatchLine)* {
    return {
      type: 'KeywordsSection',
      keywords: filterBlankLinesAndComments(keywords),
    };
  }


StringNoLF = str:(!LF c:Character {return c} )+ {
  return str.join('');
}

KeywordDefinition
  = !"*" name:StringNoLF EOL
    (Comment / BlankLine)*
    arg_definition:KeywordArgumentsDefinition?
    commands:(Comment / BlankLine / KeywordCommand / (Tab v:VariableDefinitionNoTab {return v} ) / (Tab c:CatchLine { return c; } ))*
    {
      let out = {
        type: 'KeywordDefinition',
        name: name,
        commands: filterBlankLinesAndComments(commands),
      };
      if(arg_definition){
        out.arg_definition = arg_definition;
      }
      return out;
    }

KeywordArgumentsDefinition
  = Tab "[Arguments]"i args:(Tab v:Variable {return v;})* _ Comment? EOL {
    return {
      type: 'KeywordArgumentsDefinition',
      args: args,
    };
  }

KeywordCommand
  = Tab action:(Value) args:(Tab v:Value {return v;})* EOL {
    return {
      type: 'KeywordCommand',
      action: action,
      args: args,
    };
  }


TestcasesSection =
  TestcasesSectionHeader
  testcases:(BlankLine / Comment / TestcasesDefinition / CatchLine)* {
    console.log('testcases', testcases)
    return {
      type: 'TestcasesSection',
      testcases: filterBlankLinesAndComments(testcases),
    };
  }

TestcasesDefinition
  = !"*" name:StringNoLF EOL
    commands:(Comment / BlankLine / (Tab v:VariableDefinitionNoTab {return v} ) / TestcaseSetting / TestcaseCommand / (Tab c:CatchLine { return c; } ))*
    {
      return {
        type: 'TestcaseDefinition',
        name: name,
        commands: filterBlankLinesAndComments(commands),
      }
    }

TestcaseCommand
  = Tab action:(Value) args:(Tab v:(DictValue) {return v;})* EOL {
    return {
      type: 'TestcaseCommand',
      action: action,
      args: args,
    };
  }

TestcaseSetting
  = Tab "[" setting_type:(!"]" !Tab c:Character {return c})+ "]" args:(Tab v:Value {return v;})* _ EOL {
    return {
      type: 'TestcaseSetting',
      setting_type: setting_type.join(''),
      args: args,
    };
  }

DictValue
  = key:DictKey "=" value:Value {
    return {
      type: 'DictValue',
      key: key,
      value: value,
    }
  }

DictKey
  = Variable
  / str:(!"=" c:Character {return c;} )+ { return str.join(''); }

Value
  = v1:Variable v2:Value { return { type: 'Value', values: [v1, v2] }; }
  / v1:ValueNotVariable v2:Value { return {type: 'Value', values: [v1, v2]}; }
  / v:Variable { return {type: 'Value', value: v }; }
  / v:ValueNotVariable { return { type: 'Value', value: v }; }

ValueNotVariable
  = str:(!LF !Tab !"#" c:Character {return c})+ {
    return str.join('');
  }


Setting
  = vartype:Value

DecimalDigit
  = [0-9]

NonZeroDigit
  = [1-9]

HexDigit
  = [0-9a-f]i

Number
  = [+-]? DecimalDigit+ { return parseInt(text(), 10); }

Variable
  = ScalarVariable
  / ListVariable
  / DictVariable
  / EnvVariable

Expression
  = Number
  / AlphaNumUnderscoreSpaceString

ScalarVariable
  = "${" expression:Expression "}" {
    return {
      type: 'ScalarVariable',
      expression: expression,
    };
  }

ListVariable
  = "@{" expression:Expression "}"
    index:( ( "["
      i:(
        Number
        / Variable
      )
      "]"
      ) { return i }
    )?
    {
      let out = {
        type: 'ListVariable',
        expression: expression,
      };
      if(index){
        out.index = index;
      }
      return out;
    }

DictVariable
  = "&{" expression:Expression "}"
    index:( ( "["
      i:(
        Number
        / Variable
        / AlphaNumUnderscoreSpaceString
      )
      "]"
      ) {return i}
    )?
    {
      let out = {
        type: 'ListVariable',
        expression: expression,
      };
      if(index){
        out.index = index;
      }
      return out;
    }

EnvVariable
  = "%{" expression:AlphaNumUnderscoreString "}" {
    return {
      type: 'EnvVariable',
      expression: expression,
    }
  }

Literal
  = String

AlphaNumUnderscoreString
  = ([a-zA-Z0-9_])+ { return text(); }

AlphaNumUnderscoreSpaceString
  = ([a-zA-Z0-9_] / (!Tab " "))+ { return text(); }

String
  = Character+

Character
  = !("\\") . { return text() }
  / "\\" sequence:EscapeSequence { return sequence; }

EscapeSequence
  = SingleCharacterEscapeSequence
  / HexEscapeSequence
  / UnicodeEscapeSequence
  / LongUnicodeEscapeSequence

SingleCharacterEscapeSequence
  = "$"
  / "@"
  / "%"
  / "#"
  / "="
  / "|"
  / "\\"
  / "n" { return "\n"; }
  / "r" { return "\r"; }
  / "t" { return "\t"; }
  / LF _ { return "\n"; }

HexEscapeSequence
  = "x" digits:$(HexDigit HexDigit) {
    return String.fromCharCode(parseInt(digits, 16));
  }

UnicodeEscapeSequence
  = "u" digits:$(HexDigit HexDigit HexDigit HexDigit) {
    return String.fromCharCode(parseInt(digits, 16));
  }

LongUnicodeEscapeSequence
  = "U" digits:$(HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit) {
    let point = parseInt(digits, 16);
    let offset = point - 0x10000;
    let lead = 0xd800 + (offset >> 10);
    let trail = 0xdc00 + (offset & 0x3ff);
    return String.fromCharCode(lead, trail);
  }


Tab
  = (
    "\t"
    / "  "
    / _ "|"
  ) _ {
    return {
      type: 'Tab',
      text: text(),
    }
  }

NotTabLF
  = (!Tab !LF .)+ {
    return text();
  }

