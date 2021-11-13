#!/bin/bash

cd test_data/
# python ../includes_graph.py baz1/
python ../includes_graph.py .
if [ $? -eq 0 ]; then
   cat output.graph | dot -Tsvg -o ./output.svg
fi
