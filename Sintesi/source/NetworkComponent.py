class Node:
    def __init__(self, label, id, cost, size, energy, task_energy, mobile):
        self.label = label
        self.id = id
        self.cost = cost
        self.size = size
        self.energy = energy
        self.task_energy = task_energy
        self.mobile = mobile
        self.allowed = []

    def setAllowedTask(self, task):
        self.allowed.append(task)

    def getAllowedTask(self):
        return self.allowed

    def show(self):
        print("# Node : %s" % (self.label))
        print("#     Id          : %s" % (self.id))
        print("#     Cost        : %s" % (self.cost))
        print("#     Size        : %s" % (self.size))
        print("#     Energy      : %s" % (self.energy))
        print("#     Task Energy : %s" % (self.task_energy))
        print("#     Mobile      : %s" % (self.mobile))

    @staticmethod
    def get_header():
        return "%-15s %2s %5s %10s %6s %12s %6s" % ("label",
                                                    "id",
                                                    "cost",
                                                    "size",
                                                    "energy",
                                                    "task_energy",
                                                    "mobile")

    def to_string(self):
        return "%-15s %2s %5s %10s %6s %12s %6s" % (self.label,
                                                    self.id,
                                                    self.cost,
                                                    self.size,
                                                    self.energy,
                                                    self.task_energy,
                                                    self.mobile)

    def __repr__(self):
        return "%s" % (self.label)

    def __hash__(self):
        return hash(self.label)

    def __str__(self):
        return "%s" % (self.label)

    def __cmp__(self, other):
        if hasattr(other, 'id'):
            return self.id.__cmp__(other.id)


class Channel:
    def __init__(self, label, id, cost, size, energy, df_energy, delay, error, wireless):
        self.label = label
        self.id = id
        self.cost = cost
        self.size = size
        self.energy = energy
        self.df_energy = df_energy
        self.delay = delay
        self.error = error
        self.wireless = wireless
        self.allowed = []
        self.allowedBetween = {}

    def setAllowedDataFlow(self, dataflow):
        self.allowed.append(dataflow)

    def getAllowedDataFlow(self):
        return self.allowed

    def setAllowedBetween(self, zone1, zone2):
        self.allowedBetween[zone1, zone2] = True

    def isAllowedBetween(self, zone1, zone2):
        return self.allowedBetween.get((zone1, zone2), False)

    def show(self):
        print("# Channel : %s" % (self.label))
        print("#     Id        : %s" % (self.id))
        print("#     Cost      : %s" % (self.cost))
        print("#     Size      : %s" % (self.size))
        print("#     Energy    : %s" % (self.energy))
        print("#     DF Energy : %s" % (self.df_energy))
        print("#     Delay     : %s" % (self.delay))
        print("#     Error     : %s" % (self.error))
        print("#     Wireless  : %s" % (self.wireless))

    def to_string(self):
        return "%-15s %2s %5s %10s %3s %3s %3s %3s %1s" % (self.label,
                                                           self.id,
                                                           self.cost,
                                                           self.size,
                                                           self.energy,
                                                           self.df_energy,
                                                           self.delay,
                                                           self.error,
                                                           self.wireless)

    def toScnsl(self):
        ChannelSetupName = ("csb_%s" % (self.id))
        ChToScnsl = ("Scnsl::BuiltinPlugin::CoreChannelSetup_t %s;\n" % (ChannelSetupName))
        ChToScnsl += ("%s.name         = \"%s\";\n" % (ChannelSetupName, self.label))
        ChToScnsl += ("%s.extensionId  = \"core\";\n" % (ChannelSetupName))
        ChToScnsl += ("%s.capacity     = %s;\n" % (ChannelSetupName, self.size))
        ChToScnsl += ("%s.delay        = sc_core::sc_time(%s, sc_core::SC_MS);\n" % (ChannelSetupName, self.delay))
        if (self.wireless):
            ChToScnsl += ("%s.channel_type = Scnsl::BuiltinPlugin::CoreChannelSetup_t::SHARED;\n" % (ChannelSetupName))
            ChToScnsl += ("%s.nodes_number = 0;" % (ChannelSetupName))
            ChToScnsl += (
                "%s.propagation  = Scnsl::BuiltinPlugin::CoreChannelSetup_t::EM_SPEED;\n" % (ChannelSetupName))
        else:
            ChToScnsl += (
                "%s.channel_type = Scnsl::BuiltinPlugin::CoreChannelSetup_t::FULL_DUPLEX;\n" % (ChannelSetupName))
            ChToScnsl += ("%s.capacity2    = %s;\n" % (ChannelSetupName, self.size))
        return ChToScnsl

    def __repr__(self):
        return "%s" % (self.label)

    def __hash__(self):
        return hash(self.label)

    def __str__(self):
        return "%s" % (self.label)

    def __cmp__(self, other):
        if hasattr(other, 'id'):
            return self.id.__cmp__(other.id)


class Zone:
    def __init__(self, label, x, y, z):
        self.label = label
        self.x = x
        self.y = y
        self.z = z

    def show(self):
        print("# Zone : %s" % (self.label))
        print("#     Coordinates : (%s,%s,%s)" % (self.x, self.y, self.z))

    def to_string(self):
        return "%3s %3s %3s %3s" % (self.label,
                                    self.x,
                                    self.y,
                                    self.z)

    def __repr__(self):
        return "%s" % (self.label)

    def __hash__(self):
        return hash("%s" % (self.label))

    def __str__(self):
        return "%s" % (self.label)

    def __eq__(self, other):
        return self.label == other.label


class Contiguity:
    def __init__(self, zone_one, zone_two, channel, conductance, deploymentCost):
        self.zone_one = zone_one
        self.zone_two = zone_two
        self.channel = channel
        self.conductance = conductance
        self.deploymentCost = deploymentCost

    def show(self):
        print("# Contiguity : %s" % ("Contiguity_%s_%s_%s" % (self.zone_one, self.zone_two, self.channel)))
        print("#     Zone1       :%s" % (self.zone_one))
        print("#     Zone2       :%s" % (self.zone_two))
        print("#     Channel     :%s" % (self.channel))
        print("#     Conductance :%s" % (self.conductance))
        print("#     Deployment  :%s" % (self.deploymentCost))

    def to_string(self):
        return "%3s %3s %-15s %-5s %8s" % (self.zone_one,
                                           self.zone_two,
                                           self.channel,
                                           self.conductance,
                                           self.deploymentCost)

    def __repr__(self):
        return "%s" % (self.conductance)

    def __hash__(self):
        return hash("Contiguity_%s_%s_%s" % (self.zone_one, self.zone_two, self.channel))

    def __str__(self):
        return "%s" % (self.conductance)


class Task:
    def __init__(self, id, label, size, zone, mobile):
        self.id = id
        self.label = label
        self.size = size
        self.zone = zone
        self.mobile = mobile
        self.allowed = []
        self.deployedIn = {None, int, None}

    def setAllowedNode(self, node):
        self.allowed.append(node)

    def getAllowedNode(self):
        return self.allowed

    def setDeployedIn(self, node, nodeIndex, zone):
        self.deployedIn = [node, nodeIndex, zone]

    def getDeployedIn(self):
        return self.deployedIn

    def show(self):
        print("# Task : %s" % (self.label))
        print("#     Size   : %s" % (self.size))
        print("#     Zone   : %s" % (self.zone))
        print("#     Mobile : %s" % (self.mobile))

    def to_string(self):
        return "%3s %-15s %5s %5s %1s" % (self.id,
                                          self.label,
                                          self.size,
                                          self.zone,
                                          self.mobile)

    def __repr__(self):
        return "%s" % (self.label)

    def __hash__(self):
        return hash(self.label)

    def __str__(self):
        return "%s" % (self.label)

    def __eq__(self, other):
        return self.label == other.label

    def __cmp__(self, other):
        if hasattr(other, 'id'):
            return self.id.__cmp__(other.id)


class DataFlow:
    def __init__(self, id, label, source, target, size, max_delay, max_error):
        self.id = id
        self.label = label
        self.source = source
        self.target = target
        self.size = size
        self.max_delay = max_delay
        self.max_error = max_error
        self.allowed = []
        self.deployedIn = {None, int}

    def hasTask(self, task):
        if (self.source == task):
            return True
        elif (self.target == task):
            return True
        else:
            return False

    def concernsZones(self, zone1, zone2):
        if (self.source.zone == zone1 and self.target.zone == zone2):
            return True
        elif (self.source.zone == zone2 and self.target.zone == zone1):
            return True
        else:
            return False

    def setAllowedChannel(self, channel):
        self.allowed.append(channel)

    def getAllowedChannel(self):
        return self.allowed

    def setDeployedIn(self, channel, channelIndex):
        self.deployedIn = [channel, channelIndex]

    def getDeployedIn(self):
        return self.deployedIn

    def show(self):
        print("# DataFlow : %s" % (self.label))
        print("#     Source    : %s" % (self.source))
        print("#     Target    : %s" % (self.target))
        print("#     Size      : %s" % (self.size))
        print("#     Max Delay : %s" % (self.max_delay))
        print("#     Max Error : %s" % (self.max_error))

    def to_string(self):
        return "%3s %-15s %-15s %-15s %5s %5s %5s" % (self.id,
                                                      self.label,
                                                      self.source,
                                                      self.target,
                                                      self.size,
                                                      self.max_delay,
                                                      self.max_error)

    def __repr__(self):
        return "%s" % (self.label)

    def __hash__(self):
        return hash(self.label)

    def __str__(self):
        return "%s" % (self.label)

    def __eq__(self, other):
        return self.label == other.label

    def __cmp__(self, other):
        if hasattr(other, 'id'):
            return self.id.__cmp__(other.id)


def SearchTask(list, label):
    for task in list:
        if task.label == label:
            return task
    return None


def SearchZone(list, label):
    for zone in list:
        if zone.label == label:
            return zone
    return None


def SearchChannel(list, id):
    for channel in list:
        if channel.id == id:
            return channel
    return None
