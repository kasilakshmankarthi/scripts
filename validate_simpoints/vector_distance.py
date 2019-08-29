#!/usr/bin/python

"""
This program accepts two or more basic block vectors (either in conventional or
annotated format) on stdin and returns the Euclidean and Manhattan distance
between the first vector and subsequent vector after normalizing them. The
vectors should be formatted exactly as they would appear in the .bb file, and
appear one per line.

For example, if the input contains 3 vectors, the output will be four floating
point numbers across two lines: the Euclidean and Manhattan distance between
the first and second vectors (in that order) on the first line, and the
distances between the first and third vectors on the second line.

The Euclidean distance will be between 0.0 and sqrt(2.0). sqrt(2.0) means that
the vectors are antiparallel, while 0.0 means that the vectors are parallel.

The Manhattan distance will be between 0.0 and 2.0, where the distance
represents the percentage of instructions counted in basic blocks in one of the
vectors but not in the other. (Note that it is out of a possible 200% because
each errant basic block is double-counted.)
"""

import sys
import copy

try:
    import numpy
except ImportError:
    print "Error: numpy is not installed. Please run 'apt-get install python-numpy' or your system's equivalent."
    sys.exit(1)

def line_to_bbvector_map(line):
    vector = {}
    for bb in line.strip().split(" "):
        fields = bb.split(":")
        pc = int(fields[1], 16)
        count = float(fields[2])
        vector[pc] = count
    return vector

def get_bbvector_map():
    for line in sys.stdin:
        if len(line) > 0 and line[0] == "T":
            return line_to_bbvector_map(line[1:])

# Ensure the same keys are in both vectors
def add_empty_entries(v1, v2):
    v1_keys = v1.keys()
    for key in v2.keys():
        if key not in v1_keys:
            v1[key] = 0

def bbvector_map_to_vector(bbmap):
    return numpy.array([bbmap[x] for x in sorted(bbmap.keys())])

# Check to make sure the vector was normalized properly and no bad floating point math occurred
def validate_normalized_vector(v):
    magnitude = numpy.linalg.norm(v)
    if magnitude > 1.01 or magnitude < 0.99:
        print "Error: 'normalized' vector's magnitude is not 1.0 (%f). This shouldn't be possible." % (magnitude)
        sys.exit(1)

def validate_scaled_vector(v):
    sum = numpy.sum(v)
    if sum > 1.01 or sum < 0.99:
        print "Error: 'scaled' vector's sum is not 1.0 (%f). This shouldn't be possible." % (sum)
        sys.exit(1)

def main():
    if sys.stdin.isatty():
        print __doc__
        sys.exit(0)

    v1_orig = get_bbvector_map()

    v2 = get_bbvector_map()

    while v2 is not None:
        v1 = copy.deepcopy(v1_orig)
        add_empty_entries(v1, v2)
        add_empty_entries(v2, v1)

        v1 = bbvector_map_to_vector(v1)
        v2 = bbvector_map_to_vector(v2)

        # Normalize vectors so they are magnitude 1
        v1_norm = v1/numpy.linalg.norm(v1)
        v2_norm = v2/numpy.linalg.norm(v2)

        # When creating initial vectors as integers, I saw that in some cases
        # the magnitude calculation was very wrong. I believe this was due to
        # integer overflow, and am now importing all numbers as floating point.
        # I am leaving this check in place to safeguard against similar errors
        # in the future.
        validate_normalized_vector(v1_norm)
        validate_normalized_vector(v2_norm)

        # Scale vectors so that the sum of their components is 1
        v1_scaled = v1/numpy.sum(v1)
        v2_scaled = v2/numpy.sum(v2)

        # Validate scaled vectors
        validate_scaled_vector(v1_scaled)
        validate_scaled_vector(v2_scaled)

        euclidean_distance = numpy.linalg.norm(v2_norm - v1_norm)
        absv_diff = numpy.absolute(v2_scaled - v1_scaled)
        manhattan_distance = numpy.sum(absv_diff, dtype=numpy.longfloat )
        print "%f,%f" % (euclidean_distance, manhattan_distance)

        v2 = get_bbvector_map()

if __name__ == "__main__":
    main()
