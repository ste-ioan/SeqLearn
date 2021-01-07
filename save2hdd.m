function [ output_args ] = save2hdd( fullname, data )

    dlmwrite(fullname, data, 'delimiter', '\t', 'precision', '%.4f', 'newline', 'pc');