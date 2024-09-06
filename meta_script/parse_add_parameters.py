#!/usr/bin/python
# -*- coding: UTF-8 -*-

from collections import defaultdict
def add_parameters(lines):
    """ Return 2D dict of params (and values, if applicable) which should be on
    """
    # The result object is a default dict: if keys are not
    # present, {} is returned
    result = defaultdict(dict)

    for line in lines:
        line = line.strip()
        if line and not line.startswith('#'):
            pound_pos = line.find('#')

            # A pound sign only starts an inline comment if it is preceded by
            # whitespace.
            if pound_pos > 0 and line[pound_pos - 1].isspace():
                line = line[:pound_pos].rstrip()

            fields = line.split(None, 1)
            script_id, parameter_id = fields[0].split(':')
            try:
                value = fields[1]
            except IndexError:
                continue

            if value.upper() == 'FALSE' or value.upper() == 'NONE':
                continue
            elif value.upper() == 'TRUE':
                value = None
            else:
                pass

            result[script_id][parameter_id] = value
    return result



def get_params_str(params):
    result = []
    for param_id, param_value in params.items():
        if len(param_id)>2:
            result.append('--%s' % (param_id))
        else: 
            result.append('-%s' % (param_id))
        if param_value is not None:
            result.append(param_value)
    return ' '.join(result)


