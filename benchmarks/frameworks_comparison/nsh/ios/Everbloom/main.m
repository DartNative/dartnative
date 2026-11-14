// The app's entry point: hands over to the Rust app (ios/rust).

#import <os/log.h>

extern void everbloom_main(void);

// The benchmark's marker, in the unified log (release builds too).
void everbloom_log_home_ready(void) {
    os_log(OS_LOG_DEFAULT, "SHOPBENCH home_ready");
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    everbloom_main();
    return 0;
}
