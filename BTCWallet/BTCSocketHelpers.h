//
//  Created by Admin on 9/8/16.
//

#ifndef BTCSocketHelpers_h
#define BTCSocketHelpers_h

#include <stdio.h>

int bw_nbioify(int fd);

struct bw_select_request {
    int write_fd_len;
    int read_fd_len;
    int *write_fds;
    int *read_fds;
};

struct bw_select_result {
    int error; // if > 0 there is an error
    int write_fd_len;
    int read_fd_len;
    int error_fd_len;
    int *write_fds;
    int *read_fds;
    int *error_fds;
};

struct bw_select_result bw_select(struct bw_select_request);

#endif /* BTCSocketHelpers_h */
