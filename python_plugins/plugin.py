#!/usr/bin/env python3
# -*- coding: utf-8 -*-

CODE_OK       = 0
CODE_WARNING  = 1
CODE_CRITICAL = 2
CODE_UNKNOWN  = 3


def check_range(value, range):
    # print(f'check if {value} in {range}')

    invert = False
    if range[0] == '@':
        # print('invert check')
        invert = True
        range = range[1:]

    a = range.split(':')
    if len(a) == 1:
        # print('0:MAX')
        return (value < 0 or value > float(a[0])) != invert

    if a[1]:
        # print('x:MAX')
        if a[0] == '~':
            # print('~:MAX')
            return (value > float(a[1])) != invert
        else:
            # print('MIN:MAX')
            return (value < float(a[0]) or value > float(a[1])) != invert
    else:
        # print('MIN:')
        return (value < float(a[0])) != invert

    print('Error: range not found')
    return False


if __name__ == '__main__':
    assert check_range(-1, '10')
    assert not check_range(5, '10')
    assert check_range(15, '10')

    assert check_range(5, '10:')
    assert not check_range(15, '10:')

    assert not check_range(5, '~:10')
    assert check_range(15, '~:10')

    assert check_range(5, '10:20')
    assert not check_range(15, '10:20')
    assert check_range(25, '10:20')

    assert not check_range(5, '@10:20')
    assert check_range(15, '@10:20')
    assert not check_range(25, '@10:20')
