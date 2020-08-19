#include <sys/types.h>
typedef struct {int Delta, Width; double Value; } sample;

int cmpfunc (const void * a, const void * b) {
		sample _a = (*(sample*)a ), _b = *(sample*)b;
        if (_a.Value < _b.Value)
            return -1;
        if (_a.Value > _b.Value)
            return 1;

		return 0;
}
