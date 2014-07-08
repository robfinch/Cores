#ifndef NAMETABLE_HPP
#define NAMETABLE_HPP

#include <string.h>

class NameTable {
public:
    char text[1000000];
    int length;

public:    
    NameTable() {
        text[0] = 0;
        text[1] = 0;
        length = 1;
    };
    void Clear() {
        text[0] = 0;
        text[1] = 0;
        length = 1;
    };
    char *GetName(int ndx) {
         return &text[ndx];
    };
    
    int FindName(char *nm) {
        int nn, mm;
        
        for (nn = 1; nn < length; nn++) {
            if (text[nn] == nm[0]) {
                for(mm = 1; nm[mm] == text[nn+mm] && nm[mm]; mm++);
                if (nm[mm]=='\0')
                   return nn;
            }
            else {
                while(text[nn]!=0 && nn < length) nn++;
                nn++;
            }
        }
        return -1;
    };

    int AddName(char *nm) {
        int ret;
        int olen;
        
        if ((ret = FindName(nm)) > 0)
           return ret;
        olen = length;
        strcpy(&text[length], nm);
        length += strlen(nm) + 1;
        return olen;
    };
    
    void Write(FILE *fp) {
         fwrite((void *)text, 1, length, fp);
    };
};


#endif
