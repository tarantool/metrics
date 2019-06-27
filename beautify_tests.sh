NUM_TESTS=0
NAMES=()
SOURCECODES=()

function register_test() {
    ((NUM_TESTS++))

    # read multiline source for a test
    IFS='' read -r -d '' SOURCECODE $2

    NAMES[$NUM_TESTS]=$1
    SOURCECODES[$NUM_TESTS]="$SOURCECODE"
}

function run_one() {
    NUM_TEST=$1
    NAME=${NAMES[$NUM_TEST]}
    SOURCECODE=${SOURCECODES[$NUM_TEST]}

    GREENBOLD="\033[1;32m"
    NOCOLOR="\033[0m"
    echo -e "${GREENBOLD}($1/$NUM_TESTS) Run '$NAME' test $NOCOLOR"
    eval "$SOURCECODE"
}

function run_all_tests() {
    for ((i = 1; i <= NUM_TESTS; i++)) do
        run_one $i
    done
}

