#ifndef SYMBOL_TABLE_ENTRY_H
#define SYMBOL_TABLE_ENTRY_H

#include <string>
#include <map>
#include <stack>
using namespace std;

#define UNDEFINED          -1
#define NOT_APPLICABLE      0
#define INT                 1
#define BOOLEAN             2
#define CHAR                3
#define ARRAY               4
#define PROCEDURE           5
#define PROGRAM             6

typedef struct
{
  char* value;
  int type;
  int startIndex;
  int endIndex;
  int baseType;
  int labelNum;
  int offset;
  int staticNestLevel;
  int frameSize;
} TYPE_INFO;

typedef struct
{
  int op;
  int opType;
} OPERATOR_INFO;


class SYMBOL_TABLE_ENTRY
{
  private:
    // Member variables
    string name;
    TYPE_INFO typeInfo;

  public:
    // Constructors
    SYMBOL_TABLE_ENTRY( ) { 
      name = ""; 
      typeInfo.type = UNDEFINED; 
      typeInfo.startIndex = UNDEFINED; 
      typeInfo.endIndex = UNDEFINED; 
      typeInfo.baseType = UNDEFINED; 
      typeInfo.labelNum = UNDEFINED;
      typeInfo.offset = UNDEFINED;
      typeInfo.staticNestLevel = UNDEFINED;
      typeInfo.frameSize = UNDEFINED;
    }

    SYMBOL_TABLE_ENTRY(const string theName, const int offset, const int label, const int staticNestLevel, 
      const int theType, const int startIndex, const int endIndex, const int baseType)
    {
      name = theName;
      typeInfo.type = theType;
      typeInfo.startIndex = startIndex;
      typeInfo.endIndex = endIndex;
      typeInfo.baseType = baseType;
      typeInfo.offset = offset;
      typeInfo.labelNum = label;
      typeInfo.staticNestLevel = staticNestLevel;
      typeInfo.frameSize = UNDEFINED;
    }

    // Accessors
    string getName() const { return name; }
    int getTypeInfo() const { return typeInfo.type; }
    int getStartIndex() const { return typeInfo.startIndex; }
    int getEndIndex() const { return typeInfo.endIndex; }
    int getBaseType() const { return typeInfo.baseType; }
    int getOffset() const { return typeInfo.offset; }
    int getLabelNum() const { return typeInfo.labelNum; }
    int getStaticNestLevel() const { return typeInfo.staticNestLevel; }
    int getFrameSize() const { return typeInfo.frameSize; }

    // Setters
    void setFrameSize(const int& size) { typeInfo.frameSize = size; return; }
};

#endif  // SYMBOL_TABLE_ENTRY_H
