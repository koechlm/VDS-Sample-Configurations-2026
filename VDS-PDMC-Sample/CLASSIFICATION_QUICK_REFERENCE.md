# Classification Quick Reference Card
*Vault Data Standard 2026 - Classification Extension*

---

## 🎯 What's New

### ✨ Spanish Language Support (Term ES)
- Add Spanish terms to your Term objects
- Automatically transfers to Title ES on files when checkbox is checked

### ✨ Code Property Transfer
- Code property from Class Objects and Terms now transfers to files
- No manual entry needed - automatic during classification assignment

---

## 📋 Properties That Transfer to Files

### ✅ INCLUDED (Data Properties)
These properties ARE transferred from Class/Term to files:

| Property | Description | Source |
|----------|-------------|--------|
| **Code** ✨ | Classification code/ID | Class or Term |
| **Title** | English title | Term EN (when checkbox ☑) |
| **Title DE** | German title | Term DE (when checkbox ☑) |
| **Title FR** | French title | Term FR (when checkbox ☑) |
| **Title IT** | Italian title | Term IT (when checkbox ☑) |
| **Title ES** ✨ | Spanish title | Term ES (when checkbox ☑) |
| **Custom UDPs** | Any other properties | Class or Term |

### ❌ EXCLUDED (Metadata/Hierarchy)
These properties are NOT transferred (describe classification structure):

- Segment (Level 1)
- Main Group (Level 2)
- Group (Level 3)
- Sub Group (Level 4)
- Class name
- Standard (IEC, eCl@ss, etc.)
- Level Code
- Comments, CommentsDE

---

## 🔄 Property Priority Rules

When assigning both Class Object AND Term Object:

```
Class Code = "CLS-001"  ⎤
                         ├─→ File gets: "TRM-002"
Term Code  = "TRM-002"  ⎦    (TERM WINS!)
```

**Rule**: Term properties always override Class properties

---

## 📝 How to Use

### Assigning Classification to a File

1. **Open File** in Vault Explorer
2. **Right-click** → Properties → **Classification Tab**
3. **Click** "Select Classification" button
4. **Choose Standard** (IEC 61355, eCl@ss, etc.)
5. **Navigate** using breadcrumbs (Segment → Main Group → Group → Sub Group)
6. **Select** from Tree View:
   - **Class Object** - Generic classification
   - **Class Term** - Specific term (more detailed)
7. **Preview** properties in the grid(s):
   - Class Object Properties grid (top)
   - Class Term Properties grid (bottom)
8. **Check** ☑ "Copy Term → Title Values" if you want Term languages → Title properties
9. **Click** "Select Classification"
10. **File now has** all classification properties including Code ✨ and Title ES ✨

---

## 💡 Common Scenarios

### Scenario 1: Use Class Object Only
```
Select: Class Object = "Electric Motors"
Result: File gets all properties from Electric Motors class
        Including Code (e.g., "EM-001")
```

### Scenario 2: Use Term Only
```
Select: Class Term = "3-Phase Motor, 5.5kW"
Result: File gets all properties from this specific term
        Including Code (e.g., "MOTOR-3PH-5.5") and Term translations
```

### Scenario 3: Use Both (Term Wins)
```
Class Object Code: "EM-001"
Class Term Code:   "MOTOR-3PH-5.5"
Result: File gets "MOTOR-3PH-5.5" (Term overrides Class)
```

### Scenario 4: Multilingual Titles
```
☑ Copy Term → Title Values (Multi-Languages)

Term DE: "Pumpe"
Term EN: "Pump"  
Term ES: "Bomba" ✨
Term FR: "Pompe"
Term IT: "Pompa"

Result on File:
  Title:     "Pump"   (from Term EN)
  Title DE:  "Pumpe"  (from Term DE)
  Title ES:  "Bomba"  (from Term ES) ✨ NEW
  Title FR:  "Pompe"  (from Term FR)
  Title IT:  "Pompa"  (from Term IT)
```

---

## 🔧 Administrator Setup

### Required Property Definitions

**For Custom Objects** (Class and Term objects):
- ☑ Code (Text)
- ☑ Term DE (Text)
- ☑ Term EN (Text)
- ☑ Term ES (Text) ✨ NEW
- ☑ Term FR (Text)
- ☑ Term IT (Text)

**For Files**:
- ☑ Code (Text) ✨ NEW - Now transferred automatically
- ☑ Title (Text)
- ☑ Title DE (Text)
- ☑ Title ES (Text) ✨ NEW
- ☑ Title FR (Text)
- ☑ Title IT (Text)

---

## 📊 Property Mapping Table

| Term Property | Transfers To | When | Notes |
|---------------|--------------|------|-------|
| Code | → Code | Always ✨ | NEW! Automatic transfer |
| Term DE | → Title DE | Checkbox ☑ | German |
| Term EN | → Title | Checkbox ☑ | English (default) |
| Term ES | → Title ES | Checkbox ☑ | Spanish ✨ NEW |
| Term FR | → Title FR | Checkbox ☑ | French |
| Term IT | → Title IT | Checkbox ☑ | Italian |
| Any UDP | → Same UDP | Always | Custom properties |

---

## ⚠️ Important Notes

### ✅ Do's
- ✅ Populate Code on Class Objects and Terms
- ✅ Add Term ES translations for Spanish content
- ✅ Check the "Copy Term → Title" box if you want multilingual titles
- ✅ Use Terms for specific, detailed classifications
- ✅ Use Class Objects for generic, broad classifications

### ❌ Don'ts
- ❌ Don't manually edit hierarchy properties (Level 1-4, Standard, etc.) - they're managed automatically
- ❌ Don't expect Level Code to transfer to files (it's excluded by design)
- ❌ Don't mix classification standards on the same file (choose one: IEC, eCl@ss, etc.)

---

## 🆘 Troubleshooting

**Problem**: Code property doesn't appear in property grid  
**Solution**: 
- Verify Code property is defined on the Class/Term object in Vault
- Verify Code property is defined on File entity
- Check that classification is properly assigned

**Problem**: Term ES doesn't transfer to Title ES  
**Solution**: 
- Verify "Copy Term → Title Values" checkbox is checked ☑
- Verify Term ES is populated on the Term object
- Verify Title ES property exists on File entity

**Problem**: Term Code doesn't override Class Code  
**Solution**: 
- This is expected behavior! Term should always override Class
- Check both grids to verify which Code value will be used

---

## 📚 Related Documentation

- **CLASSIFICATION_CHANGES_SUMMARY.md** - High-level overview of both changes
- **TERM_ES_IMPLEMENTATION_SUMMARY.md** - Detailed Term ES implementation
- **CODE_PROPERTY_IMPLEMENTATION.md** - Detailed Code property implementation  
- **CLASSIFICATION_PROPERTY_FLOW.md** - Visual flow diagrams and technical details

---

## 🎓 Training Resources

### For End Users
1. Watch classification assignment demo
2. Practice on test files
3. Understand Class vs Term selection
4. Learn when to use multilingual checkbox

### For Administrators
1. Review property definition requirements
2. Set up Code and Term ES properties
3. Populate existing Class/Term objects with Code values
4. Add Spanish translations to existing Terms
5. Train end users on new capabilities

---

**Questions?** Contact your Vault Administrator

*Version 1.0 - March 29, 2026*
