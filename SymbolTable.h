#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <map>
#include <string>
#include "SymbolTableEntry.h"
using namespace std;

class SYMBOL_TABLE
{
  private:
    std::map<string, SYMBOL_TABLE_ENTRY> hashTable;

  public:
    //Constructor
    SYMBOL_TABLE() { }

    // Add SYMBOL_TABLE_ENTRY x to this symbol table.
    // If successful, return true; otherwise, return false.
    bool addEntry(SYMBOL_TABLE_ENTRY x)
    {
      // Make sure there isn't already an entry with the same name
      map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
      if ((itr = hashTable.find(x.getName())) == hashTable.end())
      {
        hashTable.insert(make_pair(x.getName(), x));
        return(true);
      }
      else return(false);
    }

    bool contains(string x) 
    {
      map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
      if ((itr = hashTable.find(x)) == hashTable.end()) { return false; }

      return true;
    }

    // If a SYMBOL_TABLE_ENTRY with name theName is
    // found in this symbol table, then return true;
    // otherwise, return false.
    bool findEntry(string theName)
    {
      map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
      if ((itr = hashTable.find(theName)) == hashTable.end())
        return(false);
      else return(true);
    }

    TYPE_INFO getEntry(string theName)
    {
      map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
      itr = hashTable.find(theName);
      SYMBOL_TABLE_ENTRY s = itr->second;

      TYPE_INFO entry;
      entry.type = s.getTypeInfo();
      entry.startIndex = s.getStartIndex();
      entry.endIndex = s.getEndIndex();
      entry.baseType = s.getBaseType();
      entry.labelNum = s.getLabelNum();
      entry.staticNestLevel = s.getStaticNestLevel();
      entry.frameSize = s.getFrameSize();
      entry.offset = s.getOffset();

      return (entry);
    }

    // Set the frame size
    void setFrameSize(const string& name, const int& size) {
      map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
      itr = hashTable.find(name);
      itr->second.setFrameSize(size);
      
      return;
    }

    void print()
    {
      map<string, SYMBOL_TABLE_ENTRY>::iterator itr;
      for (itr = hashTable.begin(); itr != hashTable.end(); itr++)
      {
        string s = itr->first;
        SYMBOL_TABLE_ENTRY e = itr->second;

        printf("Symbol: %s\n", s.c_str());
        printf("Type: %d | Start Index: %d | End Index: %d | Base Type: %d\n Offset: %d | Label Number: %d | Static Nesting Level: %d | Frame Size: %d\n\n", 
          e.getTypeInfo(), e.getStartIndex(), e.getEndIndex(), e.getBaseType(), e.getOffset(), e.getLabelNum(), e.getStaticNestLevel(), e.getFrameSize());

      }
      return;
    }

    int getSize()
    {
      return (static_cast<int>(hashTable.size()));
    }

};

#endif  // SYMBOL_TABLE_H
