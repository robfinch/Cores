#ifndef NAMETABLE_H
#define NAMETABLE_H

public class NameTable {
    char text[100000];
    int length;

    NameTable() {
        text[0] = 0;
        length = 1;
    };
    
    char *GetName(int ndx) {
         return &text[ndx];
    };
    
    int FindName(char *nm) {
        int nn, mm;
        
        for (nn = 0; nn < length; nn++) {
            if (text[nn] == nm[0]) {
                for(mm = 1; nm[mm] == text[nn+mm] && nm[mm]; mm++);
                if (nm[mm]=='\0')
                   return nn;
            }
        }
        return -1;
    };

    int AddName(char *nm) {
        int reg;
        int olen;
        
        if ((ret = FindName(nm)) > 0)
           return ret;
        olen = length;
        strcpy(&text[length], nm);
        length += strlen(nm) + 1;
        return olen;
    };
    
    void write(FILE *fp) {
         fwrite((void *)text, 1, length, fp);
    };
};

#endif
