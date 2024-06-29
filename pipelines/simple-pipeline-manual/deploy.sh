#!/bin/bash

# Loop through all .yaml files in the current directory
for file in *.yaml; do
    # Apply each .yaml file using oc apply
    oc apply -f "$file"
done
