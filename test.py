#!/usr/bin/env python

import os
import re
import sys
import errno
import subprocess

root = os.path.dirname(os.path.abspath(__file__))
os.chdir(root)

class TestRunner(object):

    def __init__(self, exit_on_failure=False):
        self.exit_on_failure = exit_on_failure
        self.failed = 0

    def collect(self, path, args, input, expected, test_type):
        p = subprocess.Popen(args, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        output, err = p.communicate(input)
        exit_status = p.wait()

        def test_failed():
            print '%s test %r (%s) failed with exit status %d:' % (
                     test_type.capitalize(), test, path, exit_status)

            if expected:
                print 'Got:'

            print '\n'.join('    ' + line for line in output.splitlines())
            print '-' * 80, '\n'

            if expected:
                print 'Expected:'
                print '\n'.join('    ' + line for line in expected.splitlines())

            if self.exit_on_failure:
                sys.exit(1)

            self.failed += 1
            return False

        test, _ = os.path.splitext(os.path.split(path)[-1])
        if expected and output != expected:
            return test_failed(expected)
        elif test_type != 'error' and exit_status != 0:
            return test_failed()
        elif test_type == 'error' and exit_status == 0:
            return test_failed()

        return True

    def compile_test(self, test, input, output, test_type):
        args = ['/bin/sh', 'selma', 'temp.selma']
        self.collect(test, args, input, output, test_type=test_type)

    def run_test(self, test, input, output):
        compile_result = self.compile_test(test, input, output, test_type='compile')

        if compile_result:
            args = ['java', '-classpath', '.', 'Main']
            self.collect(test, args, input, output, test_type='run')

    def create_temp_test(self, path):
        f = open(path)
        data = f.read()
        f.close()
        input_pattern = r'<input>.*?</input>'
        output_pattern = r'<output>.*?</output>'
        sub_pattern = '((%s)|(%s))' % (input_pattern, output_pattern)

        open('temp.selma', 'w').write(re.sub(sub_pattern, '', data, re.DOTALL))

        input = re.search(input_pattern, data, re.DOTALL)
        output = re.search(output_pattern, data, re.DOTALL)
        return input and input.group(), output and output.group()

    def run(self):
        total = 0
        for subdir, dirs, files in os.walk('test'):
            for filename in files:
                if filename == 'temp.selma':
                    continue

                test, suffix = os.path.splitext(filename)
                path = os.path.join(subdir, filename)

                input, output = self.create_temp_test(path)

                if suffix.lower() == '.selma':
                    if filename.startswith(('compile_', 'error_')):
                        self.compile_test(path, input, output,
                                          test_type=filename.partition('_')[0])
                    else:
                        self.run_test(path, input, output)

                total += 1
                self.cleanup()

        print 'Ran %d test(s), SUCCESS=%d, FAILURE=%d' % (total,
                                total - self.failed, self.failed)

    def cleanup(self):
        os.remove('temp.selma')
        try:
            os.remove('temp.selma.jasmin')
        except EnvironmentError, e:
            if e.errno != errno.ENOENT:
                raise

        try:
            os.remove('Main.class')
        except EnvironmentError, e:
            if e.errno != errno.ENOENT:
                raise


if __name__ == '__main__':
    test_runner = TestRunner(exit_on_failure='--exit' in sys.argv)
    test_runner.run()
