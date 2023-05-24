#!/usr/bin/awk

BEGIN {
  print "# MEDIT"
  print "MeshVersionFormatted 1"
  print "Dimension 3"
  print "Vertices"
  elem_idx = 0
  node_idx = 0
  } 

NR == 1 {
  if ($1 != "#VRML") {
        print "Incorrect header!"
        exit 1
      } else if ($2 !~ /^V[0-9][.][0-9]/) {
        print "Incorrect header!"
        exit 1
      } else if ($3 != "utf8") {
        print "Incorrect header!"
        exit 1
      } else if (NF>3) {
        print "Incorrect header!"
        exit 1
      }
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
    # examination of x,y,z points
    if (length(coords) < 3) {
      print "There is not enough data for the coordinates."
      exit 1
    } else if (length(coords) > 3) {
      print "Too much data for the coordinates."
      exit 1
    } else {
      printf "%f %f %f\n", coords[1], coords[2], coords[3]
      i++
      node_idx++
      getline
    }

  }
}

/coordIndex[[:space:]]+\[/ {
  i = 1
  getline
  print "Triangles"
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
    
    #We write the points of the triangles only if the row has 3 number of fields (+1 because of -1).
    if (length(indices) < 4) {
      print "Not enough point for a triangle"
      exit 1
    } else if (length(indices) > 4) {
      print "Too much point for a triangle"
      exit 1
    } else {
      printf "%d %d %d\n", indices[1], indices[2], indices[3]
      i++
      elem_idx++
      getline
    }

  }
}

END {
  if (elem_idx == 0) {
    # No triangle found, print an error message
    print "Error: no triangle found"
    exit 1
  } else if (node_idx == 0) {
    # No points found, print an error message
    print "Error: no points found"
    exit 1
  }
  print "End"
}