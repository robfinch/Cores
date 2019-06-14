#ifndef NAMETABLE_H
#define NAMETABLE_H

public class NameTable {
    int length;

    NameTable() {
        nametext[0] = 0;
        length = 1;
    };
    
    char *GetName(int ndx) {
         return &nametext[ndx];
    };
    
    int FindName(char *nm) {
        int nn, mm;
        
        for (nn = 0; nn < length; nn++) {
            if (nametext[nn] == nm[0]) {
                for(mm = 1; nm[mm] == nametext[nn+mm] && nm[mm]; mm++);
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
        strcpy(&nametext[length], nm);
        length += strlen(nm) + 1;
        return olen;
    };
    
    void write(FILE *fp) {
         fwrite((void *)nametext, 1, length, fp);
    };
};

#endif
