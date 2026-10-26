classdef plotStyle
    properties
        LineSpec (1,:) char
    end
    methods
        function obj = plotStyle(ls)
            obj.LineSpec = ls;
        end
    end
    enumeration
        SolidMarker    ('-o')
        DashedMarker   ('--o')
        DottedMarker   (':o')
        DashDotMarker  ('-.o')
        Solid          ('-')
        Dashed         ('--')
        Dotted         (':')
        DashDot        ('-.')
        StarSolid      ('*-')
        StarDashed     ('*--')
    end
end
