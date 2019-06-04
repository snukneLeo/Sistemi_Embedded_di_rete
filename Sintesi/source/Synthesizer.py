#!/usr/bin/python
# File    : Synthesizer.py
# Created : 5 Mar 2015, last revision: 10 May 2016.
# Authors : Enrico Fraccaroli, Romeo Rizzi
# Content : A MILP model for the mobile network design problem proposed by Davide Quaglia et al.
# We refer to the LaTex/pdf document for a description of the model.

import time
from sys import argv, exit
#import psutil

from gurobipy import *

from networklib.NetworkChecker import *
from networklib.ScnslGenerator import *
#from networklib.TechLibPrinter import *
#from networklib.UmlForScilabPrinter import *
from networklib.NetworkInstance import *

VERBOSE = True

total_constraints = 0
valid_task_node_associations = 0
valid_df_channels_associations = 0
total_instantiated_nodes = 0
total_instantiated_channels = 0

# ---------------------------------------------------------------------------------------------------------------------
# Create the network instance.
instance = NetworkInstance(VERBOSE)


# ---------------------------------------------------------------------------------------------------------------------
def QuitSynthesizer(outcome_txt):
    instance.print_outcome(argv[1] if argc > 1 else "None",
                           outcome_txt,
                           total_constraints,
                           valid_task_node_associations,
                           valid_df_channels_associations,
                           total_instantiated_nodes,
                           total_instantiated_channels)
    exit(0)


# ---------------------------------------------------------------------------------------------------------------------
def GetSeparator():
    return "*******************************************************************************"


def Separator():
    print(GetSeparator())


# ---------------------------------------------------------------------------------------------------------------------
def Usage():
    About()
    Separator()
    print("* Usage:")
    print("*     %s [Arguments]" % os.path.basename(argv[0]))
    print("*")
    print("* Arguments:")
    print("*     [1] : Input Instance.")
    print("*     [2] : Nodes Catalogue.")
    print("*     [3] : Channels Catalogue.")
    print("*     [4] : Optimization Objective: {1:Cost (Def), 2:Energy, 3:Delay, 4:Error 5:Delay and Error}")
    print("*     [5] : Generate XML:           {0:No   (Def), 1:Yes}")
    print("*     [6] : Generate SCNSL:         {0:No   (Def), 1:Yes}")
    Separator()
    QuitSynthesizer("FAILED")


def About():
    Separator()
    print("* Network Synthesizer")
    print("* Version : 0.1")
    print("* Authors : Enrico Fraccaroli, Romeo Rizzi")
    Separator()


def GetMemoryUsage():
    # return the memory usage in MB
#    process = psutil.Process(os.getpid())
#    mem = process.memory_info()[0] / float(2 ** 20)
#    return mem
    return 0


# ---------------------------------------------------------------------------------------------------------------------
# Files parsing starting time.
instance.parsing_begin = time.clock()

# ---------------------------------------------------------------------------------------------------------------------
argc = len(argv)
if (argc <= 2) or (argc >= 8):
    Usage()

if argc >= 5:
    instance.OPTIMIZATION = int(argv[4])
    if (instance.OPTIMIZATION <= 0) or (instance.OPTIMIZATION >= 6):
        Usage()

if argc >= 6:
    instance.GENERATE_XML = int(argv[5])
    if (instance.GENERATE_XML != 0) and (instance.GENERATE_XML != 1):
        Usage()

if argc >= 7:
    instance.GENERATE_SCNSL = int(argv[6])
    if (instance.GENERATE_SCNSL != 0) and (instance.GENERATE_SCNSL != 1):
        Usage()

# ---------------------------------------------------------------------------------------------------------------------
# Start with the general information.
About()

# ---------------------------------------------------------------------------------------------------------------------
Separator()
print("* READING NODEs CATALOG FILE")
Separator()
if not instance.load_node_catalog(argv[2]):
    QuitSynthesizer("FAILED")
Separator()

# ---------------------------------------------------------------------------------------------------------------------
Separator()
print("* READING CHANNELSs CATALOG FILE")
Separator()
if not instance.load_channel_catalog(argv[3]):
    QuitSynthesizer("FAILED")
Separator()

# ---------------------------------------------------------------------------------------------------------------------
Separator()
print("* READING INPUT INSTANCE FILE")
Separator()
if not instance.load_input_instance(argv[1]):
    QuitSynthesizer("FAILED")
Separator()

# ---------------------------------------------------------------------------------------------------------------------
Separator()
print("* PERFORMING PRE-PROCESS PHASE")
Separator()
instance.perform_preprocess()
if not instance.perform_precheck():
    QuitSynthesizer("FAILED")
Separator()

# ---------------------------------------------------------------------------------------------------------------------
Separator()
if VERBOSE:
    print("* The tasks can be placed into:")
for t in instance.tasks:
    if VERBOSE:
        print("*     Task '%15s' Nodes : %s" % (t, t.getAllowedNode()))
    valid_task_node_associations += len(t.getAllowedNode())
if VERBOSE:
    print("*")
    print("* The data-flows can be placed into:")
for df in instance.dataflows:
    if VERBOSE:
        print("*     DataFlow '%15s' Channels : %s" % (df, df.getAllowedChannel()))
    valid_df_channels_associations += len(t.getAllowedNode())
if VERBOSE:
    print("*")
    print("* The nodes can host:")
    for n in instance.nodes:
        print("*     Node '%15s' Tasks : %s" % (n, n.getAllowedTask()))
    print("*")
    print("* The channels can host:")
    for c in instance.channels:
        print("*     Channel '%15s' Data-Flows : %s" % (c, c.getAllowedDataFlow()))

print("* In total there are:")
print("*     Task * Nodes    : %s" % valid_task_node_associations)
print("*     DF   * Channels : %s" % valid_df_channels_associations)
Separator()

# Files parsing ending time.
instance.parsing_end = time.clock()

# ---------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# Make the timer start.
instance.setup_begin = time.clock()

# ---------------------------------------------------------------------------------------------------------------------
Separator()
print("* GENERATING OPTIMIZATION MODEL")
Separator()

# Create the model.
m = Model('DistributedEmbeddedSystem')

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLE GENERATION
# ---------------------------------------------------------------------------------------------------------------------
Separator()
print("* GENERATING VARIABLES")
Separator()

# Create the model variables.
UB_on_N = {}
UB_on_C = {}
N = {}
C = {}
x = {}
y = {}
gamma = {}
rho = {}
w = {}
h = {}
j = {}
q = {}
# ---------------------------------------------------------------------------------------------------------------------
for n, z in itertools.product(instance.nodes, instance.zones):
    UB_on_N[n, z] = len([t for t in n.getAllowedTask() if t.zone == z])
    instance.indexSetOfClonesOfNodesInArea[n, z] = range(1, UB_on_N[n, z] + 1)
# Log the information concerning the variable.
print("*")
print("* UB_on_N [%s]" % len(UB_on_N))
if VERBOSE:
    print("* \tVariable UB_on_N is the upper-bound on the number of nodes of a certain")
    print("* \ttype inside a given zone. This value can be pre-computed.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for c in instance.channels:
    UB_on_C[c] = len(c.getAllowedDataFlow())
    instance.indexSetOfClonesOfChannel[c] = range(1, UB_on_C[c] + 1)
# Log the information concerning the variable.
print("*")
print("* UB_on_C [%s]" % len(UB_on_C))
if VERBOSE:
    print("* \tVariable UB_on_C is the upper-bound on the number of channels of a certain")
    print("* \ttype. This upper-bound can be pre-computed")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for n, z in itertools.product(instance.nodes, instance.zones):
    N[n, z] = m.addVar(lb=0.0, ub=UB_on_N[n, z], obj=0.0, vtype=GRB.CONTINUOUS, name='N_%s_%s' % (n, z))
# Log the information concerning the variable.
print("*")
print("* N [%s]" % len(N))
if VERBOSE:
    print("* \tVariable N identifies the number of deployed nodes of a certain type inside")
    print("* \ta given zone. The upper-bound on this variable is equal to UB_on_N.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for c in instance.channels:
    C[c] = m.addVar(lb=0.0, ub=UB_on_C[c], obj=0.0, vtype=GRB.CONTINUOUS, name='C_%s' % c)
# Log the information concerning the variable.
print("*")
print("* C [%s]" % len(C))
if VERBOSE:
    print("* \tVariable C identifies the number of deployed channels of a certain type.")
    print("* \tThe upper-bound on this variable is equal to UB_on_C.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for n, z in itertools.product(instance.nodes, instance.zones):
    for p in instance.indexSetOfClonesOfNodesInArea[n, z]:
        x[n, p, z] = m.addVar(lb=0.0, ub=1.0, obj=0.0, vtype=GRB.BINARY, name='x_%s_%s_%s' % (n, p, z))
# Log the information concerning the variable.
print("*")
print("* x [%s]" % len(x))
if VERBOSE:
    print("* \tVariable x identifies the number of nodes of a given type deployed inside")
    print("* \ta given zone. If the variable x[n1,n1q,z1] is true, it means that")
    print("* \tthere are n1q nodes of type n1 inside zone z1.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for c in instance.channels:
    for p in instance.indexSetOfClonesOfChannel[c]:
        y[c, p] = m.addVar(lb=0.0, ub=1.0, obj=0.0, vtype=GRB.BINARY, name='y_%s_%s' % (c, p))
# Log the information concerning the variable.
print("*")
print("* y [%s]" % len(y))
if VERBOSE:
    print("* \tVariable y identifies the number of deployed channels for a given type of")
    print("* \tchannel. In particular, if the variable y[c1,c1q] is true, it means that")
    print("* \tthere are c1q channels of type c1 deployed inside the network.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for df, t in itertools.product(instance.dataflows, instance.tasks):
    if t==df.source or t==df.target:
        gamma[df, t] = m.addVar(lb=0.0, ub=0.0, obj=0.0, vtype=GRB.BINARY, name='gamma_%s_%s' % (df, t))
    else:
        gamma[df, t] = m.addVar(lb=0.0, ub=1.0, obj=0.0, vtype=GRB.BINARY, name='gamma_%s_%s' % (df, t))
# Log the information concerning the variable.
print("*")
print("* gamma [%s]" % len(gamma))
if VERBOSE:
    print("* \tVariable gamma identifies if the tasks of the dataflow and the given task are")
    print("* \tnot placed inside the same node.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for t1, t2 in itertools.combinations(instance.tasks, 2):
    couple = frozenset([t1, t2])
    rho[couple] = m.addVar(lb=0.0, ub=1.0, obj=0.0, vtype=GRB.BINARY, name='rho_%s_%s' % (t1, t2))
# Log the information concerning the variable.
print("*")
print("* rho [%s]" % len(rho))
if VERBOSE:
    print("* \tVariable rho identifies if two tasks are deployed inside two different")
    print("* \tnodes.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for t in instance.tasks:
    for n in t.getAllowedNode():
        for p in instance.indexSetOfClonesOfNodesInArea[n, t.zone]:
            w[t, n, p] = m.addVar(lb=0.0, ub=1.0, obj=0.0, vtype=GRB.BINARY, name='w_%s_%s_%s' % (t, n, p))
# Log the information concerning the variable.
print("*")
print("* w [%s]" % len(w))
if VERBOSE:
    print("* \tVariable w identifies if the given task has been deployed inside the ")
    print("* \tgiven instance of the given type of node.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for df in instance.dataflows:
    for c in df.getAllowedChannel():
        for p in instance.indexSetOfClonesOfChannel[c]:
            h[df, c, p] = m.addVar(lb=0.0, ub=1.0, obj=0.0, vtype=GRB.BINARY, name='h_%s_%s_%s' % (df, c, p))
# Log the information concerning the variable.
print("*")
print("* h [%s]" % len(h))
if VERBOSE:
    print("* \tVariable h identifies if the given data-flow has been deployed inside the ")
    print("* \tgiven instance of the given type of channel.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for c in instance.channels:
    for z1, z2 in itertools.combinations_with_replacement(instance.zones, 2):
        couple = frozenset([z1, z2])
        q[c, couple] = c.isAllowedBetween(z1, z2)

# Log the information concerning the variable.
print("*")
print("* q [%s]" % len(q))
if VERBOSE:
    print("* \tVariable q is pre-computed and identifies if the given type of channel")
    print("* \tcan be placed between the given pair of zones.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
for c in instance.channels:
    for p in instance.indexSetOfClonesOfChannel[c]:
        j[c, p] = m.addVar(lb=0.0,
                           ub=GRB.INFINITY,
                           obj=0.0,
                           vtype=GRB.CONTINUOUS,
                           name='j_%s_%s' % (c, p))
# Log the information concerning the variable.
print("*")
print("* j [%s]" % len(j))
if VERBOSE:
    print("* \tVariable j identifies if the given instance of the given channel has ben ")
    print("* \tactually placed between the given pair of zones.")
    print("*")

# ---------------------------------------------------------------------------------------------------------------------
# Datastructures ending time.
instance.setup_end = time.clock()

# Model update (force the take in of all the variables):
m.update()

# ---------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# Constraints definition start.
instance.constraints_begin = time.clock()

print("*******************************************************************************")
print("* Defining constraints...")

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C1")
total_c1 = 0
for n, z in itertools.product(instance.nodes, instance.zones):
    total_c1 += 1
    m.addConstr(lhs=N[n, z],
                sense=GRB.EQUAL,
                rhs=quicksum(x[n, p, z] for p in instance.indexSetOfClonesOfNodesInArea[n, z]),
                name="define_N_%s_%s" % (n, z))
# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C2")
total_c2 = 0
for n, z in itertools.product(instance.nodes, instance.zones):
    for p in instance.indexSetOfClonesOfNodesInArea[n, z]:
        total_c2 += 1
        m.addConstr(lhs=N[n, z],
                    sense=GRB.GREATER_EQUAL,
                    rhs=p * x[n, p, z],
                    name="mono_clones_of_N_%s_%s_%s" % (n, z, p))
# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C3")
total_c3 = 0
for c in instance.channels:
    total_c3 += 1
    m.addConstr(lhs=C[c],
                sense=GRB.EQUAL,
                rhs=quicksum(y[c, p] for p in instance.indexSetOfClonesOfChannel[c]),
                name="define_C_%s" % c)
# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C4")
total_c4 = 0
for c in instance.channels:
    for p in instance.indexSetOfClonesOfChannel[c]:
        total_c4 += 1
        m.addConstr(lhs=C[c],
                    sense=GRB.GREATER_EQUAL,
                    rhs=p * y[c, p],
                    name="mono_clones_of_C_%s_%s" % (c, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C5")
total_c5 = 0
for t in instance.tasks:
    for n in t.getAllowedNode():
        for p in instance.indexSetOfClonesOfNodesInArea[n, t.zone]:
            total_c5 += 1
            m.addConstr(lhs=w[t, n, p],
                        sense=GRB.LESS_EQUAL,
                        rhs=x[n, p, t.zone],
                        name="codomain_existance_for_w_%s_%s_%s" % (t, n, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C6")
total_c6 = 0
for df in instance.dataflows:
    for c in df.getAllowedChannel():
        for p in instance.indexSetOfClonesOfChannel[c]:
            total_c6 += 1
            m.addConstr(lhs=h[df, c, p],
                        sense=GRB.LESS_EQUAL,
                        rhs=y[c, p],
                        name="codomain_existance_for_h_%s_%s_%s" % (df, c, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C7")
total_c7 = 0
for n, z in itertools.product(instance.nodes, instance.zones):
    for p in instance.indexSetOfClonesOfNodesInArea[n, z]:
        total_c7 += 1
        m.addConstr(lhs=x[n, p, z],
                    sense=GRB.LESS_EQUAL,
                    rhs=quicksum(w[t, n, p]
                                 for t in n.getAllowedTask()
                                 if t.zone == z),
                    name="deactivate_unecessary_clones_of_x_%s_%s_%s" % (n, z, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C8")
total_c8 = 0
for c in instance.channels:
    for p in instance.indexSetOfClonesOfChannel[c]:
        total_c8 += 1
        m.addConstr(lhs=y[c, p],
                    sense=GRB.LESS_EQUAL,
                    rhs=quicksum(h[df, c, p]
                                 for df in c.getAllowedDataFlow()),
                    name="deactivate_unecessary_clones_of_y_%s_%s" % (c, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C9")
total_c9 = 0
for n, z in itertools.product(instance.nodes, instance.zones):
    for p in instance.indexSetOfClonesOfNodesInArea[n, z]:
        total_c9 += 1
        m.addConstr(lhs=quicksum((t.size * w[t, n, p])
                                 for t in n.getAllowedTask()
                                 if t.zone == z),
                    sense=GRB.LESS_EQUAL,
                    rhs=n.size,
                    name="node_size_%s_%s" % (n, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C10")
total_c10 = 0
for c in instance.channels:
    for p in instance.indexSetOfClonesOfChannel[c]:
        total_c10 += 1
        m.addConstr(lhs=quicksum(((df.size * h[df, c, p]) /
                                  (instance.contiguities.get((df.source.zone, df.target.zone, c)).conductance if
                                   instance.contiguities.get((df.source.zone, df.target.zone, c)) is not None else
                                   # contiguity not defined
                                   (1 if df.source.zone == df.target.zone else 0)
                                   ))
                                 for df in c.getAllowedDataFlow()),
                    sense=GRB.LESS_EQUAL,
                    rhs=c.size,
                    name="channel_size_%s_%s" % (c, p))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C11")
total_c11 = 0
for t in instance.tasks:
    total_c11 += 1
    m.addConstr(lhs=quicksum(w[t, n, p]
                             for n in t.getAllowedNode()
                             for p in instance.indexSetOfClonesOfNodesInArea[n, t.zone]),
                sense=GRB.EQUAL,
                rhs=1,
                name="unique_mapping_of_task_%s" % t)

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C12 and C13")
total_c12 = 0
total_c13 = 0
for df in instance.dataflows:
    if df.source.zone == df.target.zone:
        total_c12 += 1
        m.addConstr(lhs=quicksum(h[df, c, p]
                                 for c in df.getAllowedChannel()
                                 for p in instance.indexSetOfClonesOfChannel[c]),
                    sense=GRB.EQUAL,
                    rhs=rho[frozenset([df.source, df.target])],
                    name="unique_mapping_of_dataflow_%s_same_zones" % df)
    else:
        # source.zone != target.zone
        total_c13 += 1
        m.addConstr(lhs=quicksum(h[df, c, p]
                                 for c in df.getAllowedChannel()
                                 for p in instance.indexSetOfClonesOfChannel[c]),
                    sense=GRB.EQUAL,
                    rhs=1,
                    name="unique_mapping_of_dataflow_%s_different_zones" % df)

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C14 and C15")
total_c14 = 0
total_c15 = 0
for t1, t2 in itertools.combinations(instance.tasks, 2):
    if t1.zone == t2.zone:
        for n1 in t1.getAllowedNode():
            for n1p in instance.indexSetOfClonesOfNodesInArea[n1, t1.zone]:
                for n2 in t2.getAllowedNode():
                    for n2p in instance.indexSetOfClonesOfNodesInArea[n2, t2.zone]:
                        if (n1 != n2) or (n1p != n2p):
                            total_c14 += 1
                            m.addConstr(lhs=rho[frozenset([t1, t2])],
                                        sense=GRB.GREATER_EQUAL,
                                        rhs=w[t1, n1, n1p] + w[t2, n2, n2p] - 1,
                                        name="mapping_in_different_nodes_of_%s_in_%s_%s_and_%s_in_%s_%s"
                                             % (t1, n1, n1p, t2, n2, n2p))
    else:
        # t1.zone != t2.zone
        total_c15 += 1
        m.addConstr(lhs=rho[frozenset([t1, t2])], sense=GRB.EQUAL, rhs=1,
                    name="mapping_in_different_nodes_of_%s_and_%s" % (t1, t2))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C16")
total_c16 = 0
for c in instance.channels:
    if c.point_to_point:
        for p in instance.indexSetOfClonesOfChannel[c]:
            for df1, df2 in itertools.combinations(c.getAllowedDataFlow(), 2):
                if (df1.source != df2.source) and (df1.target != df2.source):
                    total_c16 += 1
                    m.addConstr(lhs=gamma[df1, df2.source],
                                sense=GRB.LESS_EQUAL,
                                rhs=2 - h[df1, c, p] - h[df2, c, p],
                                name="point_to_point_channel_%s_%s_serves_%s_or_%s_source" % (
                                    c, p, df1, df2))

                if (df1.source != df2.target) and (df1.target != df2.target):
                    total_c16 += 1
                    m.addConstr(lhs=gamma[df1, df2.target],
                                sense=GRB.LESS_EQUAL,
                                rhs=2 - h[df1, c, p] - h[df2, c, p],
                                name="point_to_point_channel_%s_%s_serves_%s_or_%s_target" % (
                                    c, p, df1, df2))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C17")
total_c17 = 0
for df, t in itertools.product(instance.dataflows, instance.tasks):
    if df.source == t or df.target == t:
        total_c17 += 1
        m.addConstr(lhs=gamma[df, t], sense=GRB.EQUAL, rhs=0,
                    name="set_gamma_for_%s_%s_%s_a" % (t, df.source, df.target))
    elif (t.zone != df.source.zone) and (t.zone != df.target.zone) and (df.source.zone != df.target.zone):
        total_c17 += 1
        m.addConstr(lhs=gamma[df, t], sense=GRB.EQUAL, rhs=1,
                    name="set_gamma_for_%s_%s_%s_a" % (t, df.source, df.target))
    else:
        total_c17 += 1
        m.addConstr(lhs=gamma[df, t],
                    sense=GRB.GREATER_EQUAL,
                    rhs=rho[frozenset([t, df.source])] + rho[frozenset([t, df.target])] + rho[frozenset([df.source, df.target])] - 2,
                    name="set_gamma_for_%s_%s_%s_a" % (t, df.source, df.target))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C18")
total_c18 = 0
for c in instance.channels:
    if c.wireless:
        for p in instance.indexSetOfClonesOfChannel[c]:
            for df1, df2 in itertools.combinations(c.getAllowedDataFlow(), 2):
                total_c18 += 1
                m.addConstr(lhs=h[df1, c, p] + h[df2, c, p],
                            sense=GRB.LESS_EQUAL,
                            rhs=(1 +
                                 q[c, frozenset([df1.source.zone, df2.source.zone])] *
                                 q[c, frozenset([df1.source.zone, df2.target.zone])] *
                                 q[c, frozenset([df1.target.zone, df2.source.zone])] *
                                 q[c, frozenset([df1.target.zone, df2.target.zone])]),
                            name="feasible_wireless_%s_%s" % (df1.label, df2.label))

# ---------------------------------------------------------------------------------------------------------------------
print("* Constraint C19")
total_c19 = 0
for c in instance.channels:
    if not c.wireless:
        for p in instance.indexSetOfClonesOfChannel[c]:
            for d in c.getAllowedDataFlow():
                if d.source.zone != d.target.zone:
                    total_c19 += 1
                    contiguity=instance.contiguities.get((d.source.zone,d.target.zone,c))
                    if contiguity is not None:
                        m.addConstr(lhs=j[c, p],
                                    sense=GRB.GREATER_EQUAL,
                                    rhs=h[d, c, p] * contiguity.deploymentCost,
                                    name="cable_cost_%s_%s_%s" % (c.label, p, d.label))
                    else:
                        # contiguity not defined deployment cost is +infinity
                        m.addConstr(lhs=j[c, p],
                                    sense=GRB.GREATER_EQUAL,
                                    rhs=sys.maxsize,
                                    name="cable_cost_%s_%s_%s" % (c.label, p, d.label))


m.update()

total_constraints += total_c1
total_constraints += total_c2
total_constraints += total_c3
total_constraints += total_c4
total_constraints += total_c5
total_constraints += total_c6
total_constraints += total_c7
total_constraints += total_c8
total_constraints += total_c9
total_constraints += total_c10
total_constraints += total_c11
total_constraints += total_c12
total_constraints += total_c13
total_constraints += total_c14
total_constraints += total_c15
total_constraints += total_c16
total_constraints += total_c17
total_constraints += total_c18
total_constraints += total_c19
print("* Constraint C1  = %s" % total_c1)
print("* Constraint C2  = %s" % total_c2)
print("* Constraint C3  = %s" % total_c3)
print("* Constraint C4  = %s" % total_c4)
print("* Constraint C5  = %s" % total_c5)
print("* Constraint C6  = %s" % total_c6)
print("* Constraint C7  = %s" % total_c7)
print("* Constraint C8  = %s" % total_c8)
print("* Constraint C9  = %s" % total_c9)
print("* Constraint C10 = %s" % total_c10)
print("* Constraint C11 = %s" % total_c11)
print("* Constraint C12 = %s" % total_c12)
print("* Constraint C13 = %s" % total_c13)
print("* Constraint C14 = %s" % total_c14)
print("* Constraint C15 = %s" % total_c15)
print("* Constraint C16 = %s" % total_c16)
print("* Constraint C17 = %s" % total_c17)
print("* Constraint C18 = %s" % total_c18)
print("* Constraint C19 = %s" % total_c19)
print("* Constraint TOT = %s" % total_constraints)

# Constraints definition end.
instance.constraints_end = time.clock()

print("*******************************************************************************")
print("* Defining the optimization objective:")

if instance.OPTIMIZATION == 1:
    print("*    Economic Cost Minimization")
    # Economic Cost Minimization:
    #   Its objective is to minimize the global economic cost of the network.
    m.setObjective(
        quicksum(
            x[n, p, z] * n.cost
            for n, z in itertools.product(instance.nodes, instance.zones)
            for p in instance.indexSetOfClonesOfNodesInArea[n, z]) +
        quicksum(
            y[c, p] * c.cost
            for c in instance.channels
            for p in instance.indexSetOfClonesOfChannel[c]),
        GRB.MINIMIZE
    )
    m.update()
elif instance.OPTIMIZATION == 2:
    print("*    Energy Consumption Minimization")
    # Energy Consumption Minimization:
    #   The second optimization objective is to minimize the global energy consumption of the network.
elif instance.OPTIMIZATION == 3:
    print("*    Transmission Delay Minimization")
    # Transmission Delay Minimization:
    #   The third possible constrains is on the overall delay of the network.
    #   Its purpose is to minimize the global transmission delay of the network.
    m.setObjective(
        quicksum(c.delay * h[df, c, p] /
                 (instance.contiguities.get((df.source.zone, df.target.zone, c)).conductance if
                  instance.contiguities.get((df.source.zone, df.target.zone, c)) is not None else
                  # contiguity not defined
                  (1 if df.source.zone == df.target.zone else 0)
                  )
                 for df in instance.dataflows
                 for c in df.getAllowedChannel()
                 for p in instance.indexSetOfClonesOfChannel[c]),
        GRB.MINIMIZE
    )
    m.update()
elif instance.OPTIMIZATION == 4:
    print("*    Error Rate Minimization")
    # Error Rate Minimization:
    #   The optimization objective is to minimize the global error rate of the network.
    m.setObjective(
        quicksum(c.error * h[df, c, p] /
                 (instance.contiguities.get((df.source.zone, df.target.zone, c)).conductance if
                  instance.contiguities.get((df.source.zone, df.target.zone, c)) is not None else
                  # contiguity not defined
                  (1 if df.source.zone == df.target.zone else 0)
                  )
                 for df in instance.dataflows
                 for c in df.getAllowedChannel()
                 for p in instance.indexSetOfClonesOfChannel[c]),
        GRB.MINIMIZE
    )
    m.update()
elif instance.OPTIMIZATION == 5:
    print("*    Error Rate and Delay Minimization")
    # Error Rate and Delay Minimization:
    #   The optimization objective is to minimize both the global error rate and delay of the network.
    m.setObjective(
        quicksum(
            (
                    (c.delay * h[df, c, p]) / (
                    (instance.contiguities.get((df.source.zone, df.target.zone, c)).conductance if
                    instance.contiguities.get((df.source.zone, df.target.zone, c)) is not None else
                    # contiguity not defined
                    (1 if df.source.zone == df.target.zone else 0)
                    ))
                    +
                    (c.error * h[df, c, p]) / (
                        (instance.contiguities.get((df.source.zone, df.target.zone, c)).conductance if
                         instance.contiguities.get((df.source.zone, df.target.zone, c)) is not None else
                         # contiguity not defined
                         (1 if df.source.zone == df.target.zone else 0)
                         )
                    )
            ) for df in instance.dataflows for c in df.getAllowedChannel() for p in
            instance.indexSetOfClonesOfChannel[c]
        ),
        GRB.MINIMIZE
    )
    m.update()

print("*******************************************************************************")
print("* Starting optimization...")

# ---------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# SOLVER PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Controls the presolve level.
#
# A value of -1 corresponds to an automatic setting.
# Other options are off (0), conservative (1), or aggressive (2). More aggressive application of presolve
# takes more time, but can sometimes lead to a significantly tighter model.
# m.setParam("Presolve", 2)

# ---------------------------------------------------------------------------------------------------------------------
# Algorithm used to solve continuous models or the root node of a MIP model.
# Type:	int
# Default value:	-1
# Minimum value:	-1
# Maximum value:	4
#
# Options are: -1=automatic, 0=primal simplex, 1=dual simplex, 2=barrier, 3=concurrent, 4=deterministic concurrent.
# In the current release, the default Automatic (-1) setting will typically choose
# non-deterministic concurrent (Method=3) for an LP, barrier (Method=2) for a QP or QCP,
# and dual (Method=1) for the MIP root node. Only the simplex and barrier algorithms are available for continuous
# QP models. Only primal and dual simplex are available for solving the root of an MIQP model.
# Only barrier is available for continuous QCP models.
# Concurrent optimizers run multiple solvers on multiple threads simultaneously, and choose the one that
# finishes first. Deterministic concurrent (Method=4) gives the exact same result each time,
# while Method=3 is often faster but can produce different optimal bases when run multiple times.
# m.setParam("Method", 3)

# MIPGap
#
# Relative MIP optimality gap
# Type:	double
# Default value:	1e-4
# Minimum value:	0
# Maximum value:	Infinity
# The MIP solver will terminate (with an optimal result) when the relative gap between the lower and upper objective bound is less than MIPGap times the upper bound.
# m.setParam("MIPGap", 1e-4)

# MIPGapAbs
#
# Absolute MIP optimality gap
# Type:	double
# Default value:	1e-10
# Minimum value:	0
# Maximum value:	Infinity
# The MIP solver will terminate (with an optimal result) when the absolute gap between the lower and upper objective bound is less than MIPGapAbs.
# m.setParam("MIPGapAbs", 1e-10)

# OptimalityTol
#
# Dual feasibility tolerance
# Type:	double
# Default value:	1e-6
# Minimum value:	1e-9
# Maximum value:	1e-2
# Reduced costs must all be smaller than OptimalityTol in the improving direction in order for a model to be declared optimal.
# m.setParam("OptimalityTol", 1e-5)

# FeasibilityTol
#
# Primal feasibility tolerance
# Type:	double
# Default value:	1e-6
# Minimum value:	1e-9
# Maximum value:	1e-2
# All constraints must be satisfied to a tolerance of FeasibilityTol. Tightening this tolerance can produce smaller constraint violations, but for numerically challenging models it can sometimes lead to much larger iteration counts.
# m.setParam("FeasibilityTol", 1e-5)

# NumericFocus
#
# Numerical focus
# Type:	int
# Default value:	0
# Minimum value:	0
# Maximum value:	3
# The NumericFocus parameter controls the degree to which the code attempts to detect and manage numerical issues. The default setting (0) makes an automatic choice, with a slight preference for speed. Settings 1-3 increasingly shift the focus towards being more careful in numerical computations. With higher values, the code will spend more time checking the numerical accuracy of intermediate results, and it will employ more expensive techniques in order to avoid potential numerical issues.
# m.setParam("NumericFocus", 2)

# Optimization start.
instance.optimization_begin = time.clock()
# Compute optimal solution
m.optimize()
# Optimization end.
instance.optimization_end = time.clock()

# Evaluate the used memory.
instance.used_memory = GetMemoryUsage()

# Open the output file.
outfile = open(os.path.dirname(str(argv[1])) + ".result", 'a+')

if m.status == GRB.status.OPTIMAL:
    instance.sol_N = m.getAttr('x', N)
    instance.sol_C = m.getAttr('x', C)
    instance.sol_x = m.getAttr('x', x)
    instance.sol_y = m.getAttr('x', y)
    instance.sol_w = m.getAttr('x', w)
    instance.sol_h = m.getAttr('x', h)
    instance.sol_j = m.getAttr('x', j)

    # Perform post optimization.
    instance.perform_post_optimization()

    # -----------------------------------------------------------------------------------------------------------------
    outfile.write("%s\n" % GetSeparator())
    outfile.write("Optimal objective: %g\n" % m.objVal)
    outfile.write("%s\n" % GetSeparator())
    outfile.write("* SOLUTION\n")
    outfile.write("%s\n" % GetSeparator())
    outfile.write("* List of activated nodes:\n")
    NodeQuantity = {}
    for n in instance.nodes:
        NodeQuantity[n.id] = 0

    for z in instance.zones:
        for n in instance.nodes:
            if instance.sol_N[n, z]:
                NodeQuantity[n.id] = NodeQuantity[n.id] + instance.sol_N[n, z]
                total_instantiated_nodes += instance.sol_N[n, z]
                # outfile.write("*\tZone %4s, use %4g nodes of type %s\n" % (z, instance.sol_N[n, z], n))

    outfile.write("* List of activated nodes per type:\n")
    for n in instance.nodes:
        outfile.write("*\tUse %4g nodes of type %s\n" % (NodeQuantity[n.id], n))
        print("*\tUse %4g nodes of type %s" % (NodeQuantity[n.id], n))

    outfile.write("* List of activated channels:\n")
    for c in instance.channels:
        if instance.sol_C[c]:
            total_instantiated_channels += instance.sol_C[c]
            outfile.write("*\tUse %4g channels of type %s\n" % (instance.sol_C[c], c))
            print("*\tUse %4g channels of type %s" % (instance.sol_C[c], c))

    outfile.write("* Tasks allocation:\n")
    for z in instance.zones:
        for t in instance.tasks:
            if t.zone == z:
                for n in t.getAllowedNode():
                    for p in instance.indexSetOfClonesOfNodesInArea[n, z]:
                        if instance.sol_w[t, n, p]:
                            outfile.write(
                                "*\tTask     %-24s inside n Zone%s.%s.%s\n" % (t, z, n, p))

    outfile.write("* Data-Flows allocation:\n")
    for df in instance.dataflows:
        for c in df.getAllowedChannel():
            for p in instance.indexSetOfClonesOfChannel[c]:
                if instance.sol_h[df, c, p]:
                    outfile.write("*\tDataflow %-24s inside c %s.%s\n" % (df, c, p))

    outfile.write("%s\n" % GetSeparator())
    outfile.write("* STATISTICS\n")
    outfile.write("%s\n" % GetSeparator())
    outfile.write("* Economic Cost      : %s\n" % (instance.total_cost_nodes +
                                                   instance.total_cost_wirls +
                                                   instance.total_cost_cable))
    outfile.write("* \tNodes            : %s\n" % instance.total_cost_nodes)
    outfile.write("* \tWireless         : %s\n" % instance.total_cost_wirls)
    outfile.write("* \tChannels         : %s\n" % instance.total_cost_cable)
    outfile.write("* Energy Consumption : %s\n" % (instance.total_energy_nodes +
                                                   instance.total_energy_cable +
                                                   instance.total_energy_wirls))
    outfile.write("* \tNodes            : %s\n" % instance.total_energy_nodes)
    outfile.write("* \tWireless         : %s\n" % instance.total_energy_wirls)
    outfile.write("* \tCable            : %s\n" % instance.total_energy_cable)
    outfile.write("* Total Delay        : %s\n" % (instance.total_delay_wireless + instance.total_delay_cable))
    outfile.write("* \tWireless         : %s\n" % instance.total_delay_wireless)
    outfile.write("* \tCable            : %s\n" % instance.total_delay_cable)
    outfile.write("* Total Error        : %s\n" % (instance.total_error_wireless + instance.total_error_cable))
    outfile.write("* \tWireless         : %s\n" % instance.total_error_wireless)
    outfile.write("* \tCable            : %s\n" % instance.total_error_cable)
    outfile.write("%s\n" % GetSeparator())
    outfile.write("* RUNNING NETWORK CHECKER\n")
    outfile.write("%s\n" % GetSeparator())
    checker = NetworkChecker(instance.nodes,
                             instance.channels,
                             instance.zones,
                             instance.contiguities,
                             instance.tasks,
                             instance.dataflows,
                             instance.sol_N,
                             instance.sol_C,
                             instance.sol_w,
                             instance.sol_h,
                             instance.indexSetOfClonesOfChannel,
                             instance.indexSetOfClonesOfNodesInArea,
                             outfile)
    if not checker.checkNetwork():
        QuitSynthesizer("FAILED")

elif m.status == GRB.Status.INF_OR_UNBD:
    outfile.write("Model is infeasible or unbounded\n")
    m.computeIIS()
    m.write("model.ilp")
    QuitSynthesizer("FAILED")

elif m.status == GRB.Status.INFEASIBLE:
    outfile.write("Model is infeasible\n")
    m.computeIIS()
    m.write("model.ilp")
    QuitSynthesizer("FAILED")

elif m.status == GRB.Status.UNBOUNDED:
    outfile.write("Model is unbounded\n")
    QuitSynthesizer("FAILED")

else:
    outfile.write("Optimization ended with status %d\n" % m.status)
    QuitSynthesizer("FAILED")

# ---------------------------------------------------------------------------------------------------------------------
outfile.write("%s\n" % GetSeparator())
outfile.write("* FINAL STATISTICS\n")
outfile.write("%s\n" % GetSeparator())
outfile.write("*\tFile parsing           : %s s\n" % instance.get_time_parse())
outfile.write("*\tStructure creation     : %s s\n" % instance.get_time_setup())
outfile.write("*\tConstraints definition : %s s\n" % instance.get_time_constraints())
outfile.write("*\tOptimization           : %s s\n" % instance.get_time_optimization())
outfile.write("*\tTotal : %s s\n" % instance.get_time_total())
outfile.write("%s\n" % GetSeparator())
outfile.flush()
outfile.close()

# ---------------------------------------------------------------------------------------------------------------------
if instance.GENERATE_XML == 1:
    print("%s\n" % GetSeparator())
    print("* Generating UML for Scilab...")
    umlPrinter = UmlForScilabPrinter(instance.nodes,
                                     instance.channels,
                                     instance.zones,
                                     instance.contiguities,
                                     instance.tasks,
                                     instance.dataflows,
                                     instance.sol_N,
                                     instance.sol_C,
                                     instance.sol_w,
                                     instance.sol_h,
                                     instance.indexSetOfClonesOfChannel,
                                     instance.indexSetOfClonesOfNodesInArea)
    umlPrinter.printNetwork()
    print("%s\n" % GetSeparator())
    print("* Generating Technological Library...")
    techLibPrinter = TechLibPrinter(instance.nodes, instance.channels)
    techLibPrinter.printTechLib()
    print("%s\n" % GetSeparator())

# ---------------------------------------------------------------------------------------------------------------------
if instance.GENERATE_SCNSL == 1:
    scnslPrinter = ScnslGenerator(instance.nodes, instance.channels, instance.zones, instance.contiguities,
                                  instance.tasks, instance.dataflows,
                                  instance.sol_N,
                                  instance.sol_C,
                                  instance.sol_w, instance.sol_h, instance.indexSetOfClonesOfChannel,
                                  instance.indexSetOfClonesOfNodesInArea)
    scnslPrinter.printScnslNetwork("main.cc")

# ---------------------------------------------------------------------------------------------------------------------
QuitSynthesizer("SUCCESS")

exit(0)

# Copyright 2016, Enrico Fraccaroli <enrico.fraccaroli@univr.com>
# License: The MIT License (http://www.opensource.org/licenses/mit-license.php)
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
