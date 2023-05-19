#!/usr/bin/awk -f

BEGIN {
  print "# MEDIT"
  print "MeshVersionFormatted 1"
  print "Dimension 3"
  print "Vertices"
  node_idx = 1
  elem_idx = 1
  
}

/point[[:space:]]+\[/ {
  i = 1
  getline
  while ($0 !~ /\]/) {
    if (!NF) {
      # Ignore empty lines
      getline
      continue
    }
    if (/^#/) {
      # Ignore comment lines
      getline
      continue
    }
    split($0, coords)
    printf "%d %f %f %f\n", node_idx, coords[1], coords[2], coords[3]
    i++
    node_idx++
    getline
  }
}

/coordIndex[[:space:]]+\[/ {
  i = 1
  getline
  while ($0 !~ /\]/) {
    if (!NF) {
      # Ignore empty lines
      getline
      continue
    }
    if (/^#/) {
      # Ignore comment lines
      getline
      continue
    }
    split($0, indices)
    if (elem_idx == 1) {
      # First element, print the element header
      print "Triangles"
    }
    printf "%d %d %d %d\n", elem_idx, indices[1], indices[2], indices[3]
    i++
    elem_idx++
    getline
  }
}

END {
  if (elem_idx == 1) {
    # No elements found, print an error message
    print "Error: no elements found"
    exit 1
  }
  print "End"
}