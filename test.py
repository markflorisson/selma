#!/usr/bin/env python

"""
Run all selma test programs under the 'test' directory.

Input written between <input> </input> tags will be written
to the test's stdin, and the output of the program will be matched
against text between <output> </output> tags.

If a test's filename starts with compile_ it will only be compiled,
and if it starts with error_, compiling it should give an error.
"""

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
        """
        Run or compile a test as subprocess.

        args        [str]
            the arguments that constitute a subprocess invocation
        input       str
            the input to be send on stdin to the process
        expected    str
            output expected from the subprocess
        test_type   str
            what kind of test is it (compile, error or run)
        """
        print '%-10s %-50s ... ' % (test_type.capitalize(), path),

        p = subprocess.Popen(args,
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        output, err = p.communicate(input)
        exit_status = p.wait()

        if output.lstrip().startswith('Generated: Main.class'):
            _, output = output.split('\n', 1)

        def test_failed():
            "A test failed, print the output and exit status"
            #print '%s test %r (%s) failed with exit status %d:' % (
            #         test_type.capitalize(), test, path, exit_status)


            if expected:
                def print_lines(lines1, lines2):
                    "print the difference between lines1 and lines2"
                    # zip() cuts short, use map(None, ...)
                    for line1, line2 in map(None, lines1, lines2):
                        if line1 is None:
                            break

                        if line2 and line1.strip() != line2.strip():
                            marker = '    >>>'
                        else:
                            marker = '       '

                        print marker, line1

                print '  Got:'
                print_lines(output_lines, expected_lines)

                print '  Expected:'
                print_lines(expected_lines, output_lines)
            else:
                print '\n'.join(' ' * 8 + line for line in output_lines)

            print '-' * 80

            if self.exit_on_failure:
                sys.exit(1)

            self.failed += 1


        output_lines = [line.strip() for line in output.splitlines()]
        if expected:
            expected_lines = [line.strip() for line in expected.splitlines()]
        else:
            expected_lines = None

        if ((expected_lines and expected_lines != output_lines) or
                (test_type != 'error' and exit_status != 0) or
                (test_type == 'error' and exit_status == 0)):

            print 'FAIL (exit status %d)' % exit_status
            test_failed()
            return False

        print 'OK'
        return True

    def compile_test(self, test, input, output, test_type):
        args = ['/bin/sh', 'selma', 'temp.selma']
        self.collect(test, args, input, output, test_type=test_type)

    def run_test(self, test, input, output):
        compile_result = self.compile_test(test, input, output,
                                           test_type='compile')

        if compile_result:
            args = ['java', '-classpath', '.', 'Main']
            self.collect(test, args, input, output, test_type='run')

    def create_temp_test(self, path):
        """
        Copy a test specified by path to temp.selma and retrieve and input
        it should receive and any output that is expected.
        """
        f = open(path)
        data = f.read()
        f.close()
        input_pattern = r'<input>(.*?)</input>'
        output_pattern = r'<output>(.*?)</output>'
        sub_pattern = '((%s)|(%s))' % (input_pattern, output_pattern)

        def replacement(match):
            "Preserve line numbers from the original source file"
            return '\n' * match.group().count('\n')

        open('temp.selma', 'w').write(
            re.sub(sub_pattern, replacement, data, flags=re.DOTALL))

        inputs = re.findall(input_pattern, data, re.DOTALL)
        outputs = re.findall(output_pattern, data, re.DOTALL)
        return ('\n'.join(line.strip()
                    for s in inputs
                        for line in s.splitlines()
                            if line.strip()),
                '\n'.join(line.strip()
                    for s in outputs
                        for line in s.splitlines()
                            if line.strip()))

    def run(self):
        """
        Find all tests in the test subdirectory and compile and/or run them.
        """
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
        """
        Remove any temporary files. The --exit command line argument omits
        this step.
        """
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
