import sys

import itertools

from .Node import *
from .Channel import *
from .Zone import *
from .Contiguity import *
from .Task import *
from .DataFlow import *



class NetworkInstance:
    def __init__(self, VERBOSE):
        self.VERBOSE = VERBOSE

        self.channels = []
        self.nodes = []
        self.zones = []
        self.contiguities = {}
        self.tasks = []
        self.dataflows = []

        # The input arguments.
        self.OPTIMIZATION = 1
        self.GENERATE_XML = 0
        self.GENERATE_SCNSL = 0

        # Optimization Results
        # Economic Cost
        self.total_cost_nodes = 0
        self.total_cost_cable = 0
        self.total_cost_wirls = 0
        # Energy Consumption
        self.total_energy_nodes = 0
        self.total_energy_cable = 0
        self.total_energy_wirls = 0
        # Communication Delay
        self.total_delay_cable = 0
        self.total_delay_wireless = 0
        # Error Rate
        self.total_error_cable = 0
        self.total_error_wireless = 0

        # Timers
        self.parsing_begin = 0
        self.parsing_end = 0
        self.setup_begin = 0
        self.setup_end = 0
        self.constraints_begin = 0
        self.constraints_end = 0
        self.optimization_begin = 0
        self.optimization_end = 0

        # General information.
        self.used_memory = 0

        self.indexSetOfClonesOfNodesInArea = {}
        self.indexSetOfClonesOfChannel = {}

        # Solved variables.
        self.sol_N = 0
        self.sol_C = 0
        self.sol_x = 0
        self.sol_y = 0
        self.sol_w = 0
        self.sol_h = 0
        self.sol_j = 0

        # Output files.
        self.outcome = None
        self.outfile = None

    def get_time_parse(self):
        return self.parsing_end - self.parsing_begin

    def get_time_setup(self):
        return self.setup_end - self.setup_begin

    def get_time_constraints(self):
        return self.constraints_end - self.constraints_begin

    def get_time_optimization(self):
        return self.optimization_end - self.optimization_begin

    def get_time_total(self):
        return self.get_time_parse() + self.get_time_setup() + self.get_time_constraints() + self.get_time_optimization()

    def print_outcome(self, test_case,
                      outcome_result,
                      total_constraints,
                      valid_task_node_associations,
                      valid_df_channels_associations,
                      total_instantiated_nodes,
                      total_instantiated_channels):
        self.outcome = open("result.txt", 'a+')
        tot_co = self.total_cost_nodes + self.total_cost_wirls + self.total_cost_cable
        tot_en = self.total_energy_nodes + self.total_energy_wirls + self.total_energy_cable
        tot_de = self.total_delay_wireless + self.total_delay_cable
        tot_er = self.total_error_wireless + self.total_error_cable

        self.outcome.write("| %-42s " % test_case)
        self.outcome.write("| %d" % self.OPTIMIZATION)
        self.outcome.write("| %-7s" % outcome_result)
        self.outcome.write("| %10d" % len(self.tasks))
        self.outcome.write("| %10d" % len(self.dataflows))
        self.outcome.write("| %10d" % len(self.zones))
        self.outcome.write("| %8.2f" % self.get_time_parse())
        self.outcome.write("| %8.2f" % self.get_time_setup())
        self.outcome.write("| %8.2f" % self.get_time_constraints())
        self.outcome.write("| %8.2f" % self.get_time_optimization())
        self.outcome.write("| %8.2f" % self.get_time_total())
        self.outcome.write("| %8.2f" % self.used_memory)
        self.outcome.write("| %10d" % total_constraints)
        self.outcome.write("| %10d" % valid_task_node_associations)
        self.outcome.write("| %10d" % valid_df_channels_associations)
        self.outcome.write("| %10d" % total_instantiated_nodes)
        self.outcome.write("| %10d" % total_instantiated_channels)
        self.outcome.write("| %10.2f" % tot_co)
        self.outcome.write("| %10.2f" % tot_en)
        self.outcome.write("| %10.2f" % tot_de)
        self.outcome.write("| %10.2f" % tot_er)
        self.outcome.write("|\n")
        self.outcome.flush()
        self.outcome.close()

    def add_channel(self, channel):
        self.channels.append(channel)

    def add_node(self, node):
        self.nodes.append(node)

    def add_zone(self, zone):
        self.zones.append(zone)

    def add_contiguity(self, contiguity):
        self.contiguities.append(contiguity)

    def add_taks(self, taks):
        self.tasks.append(taks)

    def add_data_flow(self, data_flow):
        self.dataflows.append(data_flow)

    def load_node_catalog(self, node_catalog_filename):
        if self.VERBOSE:
            print("* %s" % Node.get_header_caps())
        with open(node_catalog_filename, "r") as node_file:
            for line in node_file:
                node_line = line.strip()
                # Skip empty lines.
                if not node_line:
                    continue
                # Skip comments.
                if (node_line[0] == ';') or (node_line[0] == '#'):
                    continue
                # Retrieve the values from the file.
                try:
                    label, id, cost, size, energy, task_energy, energy_cost, mobile = node_line.split()
                except ValueError:
                    print("Error: Wrong line format '%s'" % node_line)
                    return False
                # Create a new node.
                new_node = Node(label,
                                int(id),
                                int(cost),
                                int(size),
                                int(energy),
                                int(task_energy),
                                float(energy_cost),
                                int(mobile))
                # Append the node to the list of nodes.
                self.add_node(new_node)
                # Print the node.
                if self.VERBOSE:
                    print("* %s" % new_node.to_string())
        return True

    def load_channel_catalog(self, channel_catalog_filename):
        if self.VERBOSE:
            print("* %s" % Channel.get_header_caps())
        with open(channel_catalog_filename, "r") as channel_file:
            for line in channel_file:
                channel_line = line.strip()
                # Skip empty lines.
                if not channel_line:
                    continue
                # Skip comments.
                if (channel_line[0] == ';') or (channel_line[0] == '#'):
                    continue
                # Retrieve the values from the file.
                try:
                    label, id, cost, size, energy, df_energy, energy_cost, delay, error, wireless, point_to_point = channel_line.split()
                except ValueError:
                    print("Error: Wrong line format '%s'" % channel_line)
                    return False
                # Create a new Channel.
                new_channel = Channel(label,
                                      int(id),
                                      int(cost),
                                      int(size),
                                      int(energy),
                                      int(df_energy),
                                      float(energy_cost),
                                      int(delay),
                                      int(error),
                                      int(wireless),
                                      int(point_to_point))
                # Append the channel to the list of channels.
                self.add_channel(new_channel)
                # Print the channel.
                if self.VERBOSE:
                    print("* %s" % new_channel.to_string())
        return True

    def load_input_instance(self, input_instance_filename):
        is_parsing_zone = False
        is_parsing_contiguity = False
        is_parsing_task = False
        is_parsing_dataflow = False
        index_task = 1
        index_dataflow = 1
        with open(input_instance_filename, "r") as input_file:
            for line in input_file:
                input_line = line.strip()
                # Skip empty lines.
                if not input_line:
                    continue
                # Skip comments.
                if (input_line[0] == ';') or (input_line[0] == '#'):
                    continue
                # -----------------------------------------------------------------------------------------------------
                # Parse the line.
                if input_line == "<ZONE>":
                    is_parsing_zone = True
                    if self.VERBOSE:
                        print("* LOADING ZONES")
                elif input_line == "</ZONE>":
                    is_parsing_zone = False
                    if self.VERBOSE:
                        print("* LOADING ZONES - Done")
                elif is_parsing_zone:
                    # Retrieve the values from the file.
                    try:
                        label, x, y, z = input_line.split()
                    except ValueError:
                        print("Error: Wrong line format '%s'" % input_line)
                        return False
                    # Create a new zone.
                    new_zone = Zone(int(label), int(x), int(y), int(z))
                    # Append the zone to the list of zones.
                    self.add_zone(new_zone)
                    # Print the zone.
                    if self.VERBOSE:
                        print("* %s" % new_zone.to_string())

                # -----------------------------------------------------------------------------------------------------
                elif input_line == "<CONTIGUITY>":
                    is_parsing_contiguity = True
                    if self.VERBOSE:
                        print("* LOADING CONTIGUITIES")
                elif input_line == "</CONTIGUITY>":
                    is_parsing_contiguity = False
                    if self.VERBOSE:
                        print("* LOADING CONTIGUITIES - Done")
                elif is_parsing_contiguity:
                    # Retrieve the values from the file.
                    try:
                        id_zone1, id_zone2, id_channel, conductance, deployment_cost = input_line.split()
                    except ValueError:
                        print("Error: Wrong line format '%s'" % input_line)
                        return False
                    # Search the instance of the first zone.
                    zone1 = SearchZone(self.zones, int(id_zone1))
                    if zone1 is None:
                        print("[Error] Can't find zone : %s" % id_zone1)
                        return False
                    # Search the instance of the first zone.
                    zone2 = SearchZone(self.zones, int(id_zone2))
                    if zone2 is None:
                        print("[Error] Can't find zone : %s" % id_zone2)
                        return False
                    # Search the instance of the channel.
                    if zone1 == zone2:
                        print("[Error] Contiguity between two equal zone : %s" % id_zone2)
                    channel = SearchChannel(self.channels, int(id_channel))
                    if channel is None:
                        print("[Error] Can't find channel : %s" % id_channel)
                        return False
                    # Create the new contiguity.
                    new_contiguity = Contiguity(zone1,
                                                zone2,
                                                channel,
                                                float(conductance),
                                                float(deployment_cost))
                    # Add the contiguity to the list of contiguities.
                    self.contiguities[zone1, zone2, channel] = new_contiguity
                    # Set the same values for the vice-versa of the zones.
                    self.contiguities[zone2, zone1, channel] = new_contiguity
                    # Print the contiguity.
                    if self.VERBOSE:
                        print("* %s" % new_contiguity.to_string())

                # -----------------------------------------------------------------------------------------------------
                elif input_line == "<TASK>":
                    is_parsing_task = True
                    if self.VERBOSE:
                        print("* LOADING TASKS")
                elif input_line == "</TASK>":
                    is_parsing_task = False
                    if self.VERBOSE:
                        print("* LOADING TASKS - Done")
                elif is_parsing_task:
                    # Retrieve the values from the file.
                    try:
                        label, size, id_zone, mobile = input_line.split()
                    except ValueError:
                        print("Error: Wrong line format '%s'" % input_line)
                        return False
                    # Search the instance of the zone.
                    zone = SearchZone(self.zones, int(id_zone))
                    if zone is None:
                        print("[Error] Can't find zone : %s" % id_zone)
                        return False
                    # Create the new task.
                    new_task = Task(index_task, label, int(size), zone, int(mobile))
                    # Append the task to the list of tasks.
                    self.add_taks(new_task)
                    # Increment the task index
                    index_task += 1
                    # Print the task.
                    if self.VERBOSE:
                        print("* %s" % new_task.to_string())

                # -----------------------------------------------------------------------------------------------------
                elif input_line == "<DATAFLOW>":
                    is_parsing_dataflow = True
                    if self.VERBOSE:
                        print("* LOADING DATA-FLOWS")
                elif input_line == "</DATAFLOW>":
                    is_parsing_dataflow = False
                    if self.VERBOSE:
                        print("* LOADING DATA-FLOWS - Done")
                elif is_parsing_dataflow:
                    # Retrieve the values from the file.
                    try:
                        label, id_source, id_target, band, delay, error = input_line.split()
                    except ValueError:
                        print("Error: Wrong line format '%s'" % input_line)
                        return False
                    # Search the instance of the source task.
                    source = SearchTask(self.tasks, id_source)
                    if source is None:
                        print("[Error] Can't find the source task : %s" % id_source)
                        return False
                    # Search the instance of the target task.
                    TargetTask = SearchTask(self.tasks, id_target)
                    if TargetTask is None:
                        print("[Error] Can't find the target task : %s" % id_target)
                        return False
                    # Check if the source and target task are the same.
                    if source == TargetTask:
                        print("[Error] Can't define a dataflow between the same task : %s -> %s"
                              % (source, TargetTask))
                        return False
                    # Create the new Data-Flow
                    NewDataFlow = DataFlow(index_dataflow,
                                           label,
                                           source,
                                           TargetTask,
                                           int(band),
                                           int(delay),
                                           int(error))
                    # Append the data-flow to the list of data-flows.
                    self.add_data_flow(NewDataFlow)
                    # Print the data-flow.
                    if self.VERBOSE:
                        print("* %s" % NewDataFlow.to_string())
                    # Increment the index of data-flows.
                    index_dataflow += 1
        return True

    def perform_preprocess(self):
        print("* Checking in which nodes the tasks can be placed into...")
        for task, node in itertools.product(self.tasks, self.nodes):
            # Check if the task and the node are compatible.
            if task.mobile != node.mobile:
                continue
            # Check if the task can be contained inside the node.
            if task.size > node.size:
                continue
            # Link node and task.
            task.setAllowedNode(node)
            node.setAllowedTask(task)

        print("* Checking in which channels the data-flows can be placed into...")
        for dataflow, channel in itertools.product(self.dataflows, self.channels):
            contiguity = self.contiguities.get((dataflow.source.zone, dataflow.target.zone, channel))
            if contiguity is None:
                # contiguity not specified from input file
                if dataflow.source.zone!=dataflow.target.zone:
                    # different zone can't use this channel
                    continue
                else:
                    # same zone this channel is allowed
                    if channel.size >= dataflow.size and channel.error<=dataflow.max_error and channel.delay<=dataflow.max_delay:
                        # channel size/error/delay compatible with dataflow
                        if not (((dataflow.source.mobile or dataflow.target.mobile) and not channel.wireless)):
                            # channel respect wireless constraints for dataflow
                            dataflow.setAllowedChannel(channel)
                            channel.setAllowedDataFlow(dataflow)
                        else:
                            continue
                    else:
                        continue
            else:
                # contiguity is specified
                # Check the conductance of the contiguity.
                if contiguity.conductance <= 0:
                    continue
                # Check if the channel can hold the data-flow give the conductance value.
                if channel.size < (dataflow.size / contiguity.conductance):
                    continue
                # Check if the channel has the required error_rate demanded by the data-flow give the conductance value.
                if channel.error > (dataflow.max_error * contiguity.conductance):
                    continue
                # Check if the channel has the required delay demanded by the data-flow give the conductance value.
                if channel.delay > (dataflow.max_delay * contiguity.conductance):
                    continue
                # If a node is mobile, then it can be connected only to wireless channels.
                if ((dataflow.source.mobile or dataflow.target.mobile) and not channel.wireless):
                    continue
                # Link dataflow and channel.
                dataflow.setAllowedChannel(channel)
                channel.setAllowedDataFlow(dataflow)

        print("* Checking between which zones a channel can be used to connect nodes...")
        for channel in self.channels:
            for zone1, zone2 in itertools.combinations_with_replacement(self.zones, 2):
                contiguity=self.contiguities.get((zone1, zone2, channel))
                if contiguity is None:
                    # contiguity is not specified from input file
                    if zone1==zone2:
                        # same zone this channel is allowed
                        channel.setAllowedBetween(zone1, zone2)
                else:
                    # contiguity is specified
                    if contiguity.conductance > 0:
                        channel.setAllowedBetween(zone1, zone2)

    def perform_precheck(self):
        print("* Checking if there is at least one suitable node for each task...")
        for task in self.tasks:
            if len(task.getAllowedNode()) == 0:
                print("There are no nodes that can contain task %s." % task)
                return False

        print("* Checking if there are suitable channels for data-flows which cross zones...")
        for dataflow in self.dataflows:
            if len(dataflow.getAllowedChannel()) == 0:
                # Get the source and target node
                source_node = dataflow.source
                target_node = dataflow.target
                # If the tasks resides in different zones, then there is no way the dataflow can be correctly placed.
                if source_node.zone != target_node.zone:
                    print("There are no channels that can contain data-flow %s." % dataflow)
                    for channel in self.channels:
                        reason = "no reason"
                        contiguity = self.contiguities.get((source_node.zone, target_node.zone, channel))
                        if contiguity is not None:
                            # contiguity specified
                            if contiguity.conductance <= 0:
                                reason = "low conductance %s" % contiguity.conductance
                            elif channel.size < (dataflow.size / contiguity.conductance):
                                reason = "low size"
                            elif channel.error > (dataflow.max_error * contiguity.conductance):
                                reason = "higher error rate"
                            elif channel.delay > (dataflow.max_delay * contiguity.conductance):
                                reason = "higher delay"
                            elif ((source_node.mobile or target_node.mobile) and not channel.wireless):
                                reason = "unacceptable mobile/wireless"
                        else:
                            # contiguity is not specified
                            reason= "low conductance 0"
                        print("\tChannel %s for %s." % (channel, reason))
                    return False
                # If they resides in the same zone, there is a chance that the two tasks can be placed inside the same,
                # node. However, this must be checked.
                SumSizes = source_node.size + target_node.size
                CanBeContained = False
                for node in set(source_node.getAllowedNode()).intersection(target_node.getAllowedNode()):
                    if node.size >= SumSizes:
                        CanBeContained = True
                        break

                if not CanBeContained:
                    print("There are no channels that can contain data-flow %s." % dataflow)
                    print("And also there is no node which can contain both of its tasks.")
                    return False
        return True

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def perform_post_optimization(self):
        # -------------------------------------------------------------------------------------------------------------
        # Set where the dataflows are deployed.
        for c in self.channels:
            if not c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    for df in c.getAllowedDataFlow():
                        if self.sol_h[df, c, p]:
                            df.setDeployedIn(c, p)

        # -------------------------------------------------------------------------------------------------------------
        # Set where the tasks are deployed.
        for n, z in itertools.product(self.nodes, self.zones):
            for p in self.indexSetOfClonesOfNodesInArea[n, z]:
                if self.sol_x[n, p, z]:
                    for t in n.getAllowedTask():
                        if (t.zone == z) and self.sol_w[t, n, p]:
                            t.setDeployedIn(n, p, z)

        # Evaluate the costs.
        self.total_cost_nodes = self.get_node_cost()
        self.total_cost_cable = self.get_cable_cost()
        self.total_cost_wirls = self.get_wireless_cost()

        # Evaluate the energy consumption.
        self.total_energy_nodes = self.get_node_energy()
        self.total_energy_cable = self.get_cable_energy()
        self.total_energy_wirls = self.get_wireless_energy()

        # Evaluate the delay.
        self.total_delay_cable = self.get_cable_delay()
        self.total_delay_wireless = self.get_wireless_delay()

        # Evaluate the error.
        self.total_error_cable = self.get_cable_error()
        self.total_error_wireless = self.get_wireless_error()

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_node_cost(self):
        total_cost_nodes = 0

        # -------------------------------------------------------------------------------------------------------------
        # Add the intrinsic cost of the nodes.
        for n, z in itertools.product(self.nodes, self.zones):
            for p in self.indexSetOfClonesOfNodesInArea[n, z]:
                if self.sol_x[n, p, z]:
                    total_cost_nodes += (n.cost + n.energy * n.energy_cost)

        # -------------------------------------------------------------------------------------------------------------
        # Add the cost of tasks inside the nodes.
        for n, z in itertools.product(self.nodes, self.zones):
            for p in self.indexSetOfClonesOfNodesInArea[n, z]:
                if self.sol_x[n, p, z]:
                    for t in n.getAllowedTask():
                        if (t.zone == z) and self.sol_w[t, n, p]:
                            total_cost_nodes += (t.size * n.task_energy * n.energy_cost)

        return total_cost_nodes

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_wireless_cost(self):
        total_cost_wirls = 0
        # -------------------------------------------------------------------------------------------------------------
        # Add the intrinsic cost of the wireless channel.
        for c in self.channels:
            if c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    if self.sol_y[c, p]:
                        total_cost_wirls += (c.cost + c.energy * c.energy_cost)

        # -------------------------------------------------------------------------------------------------------------
        # Considers also the dataflows placed inside the channels.
        for c in self.channels:
            if c.wireless:
                for df in c.getAllowedDataFlow():
                    contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                    for p in self.indexSetOfClonesOfChannel[c]:
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_cost_wirls += (c.df_energy * df.size * c.energy_cost) / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_cost_wirls += (c.df_energy * df.size * c.energy_cost)
                                else:
                                    total_cost_wirls += (c.df_energy * df.size * c.energy_cost) / 0

        # -------------------------------------------------------------------------------------------------------------
        return total_cost_wirls

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_cable_cost(self):
        total_cost_cable = 0
        # -------------------------------------------------------------------------------------------------------------
        # Add the intrinsic cost of the wired channel.
        for c in self.channels:
            if not c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    if self.sol_y[c, p]:
                        total_cost_cable += (c.cost + c.energy * c.energy_cost)

        # -------------------------------------------------------------------------------------------------------------
        # Considers also the dataflows placed inside the channels.
        for c in self.channels:
            if not c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    for df in c.getAllowedDataFlow():
                        if self.sol_h[df, c, p]:
                            contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                            if contiguity is not None:
                                total_cost_cable += (c.df_energy * df.size * c.energy_cost) / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_cost_cable += (c.df_energy * df.size * c.energy_cost)
                                else:
                                    total_cost_cable += (c.df_energy * df.size * c.energy_cost)/0

        # -------------------------------------------------------------------------------------------------------------
        # Considers also the deployment cost.
        for c in self.channels:
            if not c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    if self.sol_j[c, p] > 0:
                        total_cost_cable += self.sol_j[c, p]

        return total_cost_cable

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_node_energy(self):
        total_cost_nodes = 0

        # -------------------------------------------------------------------------------------------------------------
        # Add the intrinsic cost of the nodes.
        for n, z in itertools.product(self.nodes, self.zones):
            for p in self.indexSetOfClonesOfNodesInArea[n, z]:
                if self.sol_x[n, p, z]:
                    total_cost_nodes += n.energy

        # -------------------------------------------------------------------------------------------------------------
        # Add the cost of tasks inside the nodes.
        for n, z in itertools.product(self.nodes, self.zones):
            for p in self.indexSetOfClonesOfNodesInArea[n, z]:
                if self.sol_x[n, p, z]:
                    for t in n.getAllowedTask():
                        if (t.zone == z) and self.sol_w[t, n, p]:
                            total_cost_nodes += (t.size * n.task_energy)

        return total_cost_nodes

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_wireless_energy(self):
        total_energy_channels = 0
        # -------------------------------------------------------------------------------------------------------------
        # Add the intrinsic cost of the wireless channel.
        for c in self.channels:
            if c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    if self.sol_y[c, p]:
                        total_energy_channels += c.energy

        # -------------------------------------------------------------------------------------------------------------
        # Considers also the dataflows placed inside the channels.
        for c in self.channels:
            if c.wireless:
                for df in c.getAllowedDataFlow():
                    contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                    for p in self.indexSetOfClonesOfChannel[c]:
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_energy_channels += (c.df_energy * df.size) / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_energy_channels += (c.df_energy * df.size)
                                else:
                                    total_energy_channels += (c.df_energy * df.size)/0

        # -------------------------------------------------------------------------------------------------------------
        return total_energy_channels

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_cable_energy(self):
        total_energy_channels = 0
        # -------------------------------------------------------------------------------------------------------------
        # Add the intrinsic cost of the wired channel.
        for c in self.channels:
            if not c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    if self.sol_y[c, p]:
                        total_energy_channels += c.energy

        # -------------------------------------------------------------------------------------------------------------
        # Considers also the dataflows placed inside the channels.
        for c in self.channels:
            if not c.wireless:
                for p in self.indexSetOfClonesOfChannel[c]:
                    for df in c.getAllowedDataFlow():
                        contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_energy_channels += (c.df_energy * df.size) / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_energy_channels += (c.df_energy * df.size)
                                else:
                                    total_energy_channels += (c.df_energy * df.size) / 0

        return total_energy_channels

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_wireless_delay(self):
        total_delay = 0
        # -------------------------------------------------------------------------------------------------------------
        # Considers the dataflows placed inside the channels.
        for c in self.channels:
            if c.wireless:
                for df in c.getAllowedDataFlow():
                    contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                    for p in self.indexSetOfClonesOfChannel[c]:
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_delay += c.delay / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_delay += c.delay
                                else:
                                    total_delay += c.delay / 0
        # -------------------------------------------------------------------------------------------------------------
        return total_delay

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_cable_delay(self):
        total_delay = 0
        # -------------------------------------------------------------------------------------------------------------
        # Considers the dataflows placed inside the channels.
        for c in self.channels:
            if not c.wireless:
                for df in c.getAllowedDataFlow():
                    contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                    for p in self.indexSetOfClonesOfChannel[c]:
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_delay += c.delay / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_delay += c.delay
                                else:
                                    total_delay += c.delay / 0
        # -------------------------------------------------------------------------------------------------------------
        return total_delay

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_wireless_error(self):
        total_error = 0
        # -------------------------------------------------------------------------------------------------------------
        # Considers the dataflows placed inside the channels.
        for c in self.channels:
            if c.wireless:
                for df in c.getAllowedDataFlow():
                    contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                    for p in self.indexSetOfClonesOfChannel[c]:
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_error += c.error / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_error += c.error
                                else:
                                    total_error += c.error / 0
        # -------------------------------------------------------------------------------------------------------------
        return total_error

    # -----------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------
    def get_cable_error(self):
        total_error = 0
        # -------------------------------------------------------------------------------------------------------------
        # Considers the dataflows placed inside the channels.
        for c in self.channels:
            if not c.wireless:
                for df in c.getAllowedDataFlow():
                    contiguity = self.contiguities.get((df.source.zone, df.target.zone, c))
                    for p in self.indexSetOfClonesOfChannel[c]:
                        if self.sol_h[df, c, p]:
                            if contiguity is not None:
                                total_error += c.error / contiguity.conductance
                            else:
                                # contiguity is not defined
                                if df.source.zone == df.target.zone:
                                    total_error += c.error
                                else:
                                    total_error += c.error / 0
        # -------------------------------------------------------------------------------------------------------------
        return total_error
