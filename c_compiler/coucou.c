// commentaire
#include <stdio.h>
#ifndef coucou
#define coucou 12
%:endif

#define print printf

int main() {
    print("hello world\n"); /* commentaire */
    // commentaire
    /*
     *
     * commentaire
     */
    return 10;
}
