require 'opencv'

require './tabula.rb'

module Tabula
  module Rulings

    class Ruling < ZoneEntity
      attr_accessor :x1, :y1, :x2, :y2

      # 2D line intersection test taken from comp.graphics.algorithms FAQ
      def intersects?(other)
        r = ((self.top-other.top)*(other.right-other.left) - (self.left-other.left)*(other.bottom-other.top)) \
             / ((self.right-self.left)*(other.bottom-other.top)-(self.bottom-self.top)*(other.right-other.left))

        s = ((self.top-other.top)*(self.right-self.left) - (self.left-other.left)*(self.bottom-self.top)) \
            / ((self.right-self.left)*(other.bottom-other.top) - (self.bottom-self.top)*(other.right-other.left))

        r >= 0 and r < 1 and s >= 0 and s < 1
      end

      def vertical?
        left == right
      end

      def horizontal?
        top == bottom
      end

      def to_json(arg)
        [left, top, right, bottom].to_json
      end

      def to_xml
        "<ruling x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\" />" \
         % [left, top, right, bottom]
      end

      # // Test to see if a line intersects a Rectangle
      # bool LineIntersectsRect( const Vector2f &v1, const Vector2f &v2, const Rect &r )
      # {
      #   Vector2f lowerLeft( r.x, r.y+r.height );
      #   Vector2f upperRight( r.x+r.width, r.y );
      #   Vector2f upperLeft( r.x, r.y );
      #   Vector2f lowerRight( r.x+r.width, r.y+r.height);
      #   // check if it is inside
      #   if (v1.x > lowerLeft.x && v1.x < upperRight.x && v1.y < lowerLeft.y && v1.y > upperRight.y &&
      #       v2.x > lowerLeft.x && v2.x < upperRight.x && v2.y < lowerLeft.y && v2.y > upperRight.y )
      #     {
      #       return true;
      #     }
      #     // check each line for intersection
      #     if (LineIntersectLine(v1,v2, upperLeft, lowerLeft ) ) return true;
      #     if (LineIntersectLine(v1,v2, lowerLeft, lowerRight) ) return true;
      #     if (LineIntersectLine(v1,v2, upperLeft, upperRight) ) return true;
      #     if (LineIntersectLine(v1,v2, upperRight, lowerRight) ) return true;
      #     return false;
      # }

    end

    # generate an xml string of
    def Rulings.to_xml(rulings)
    end

    def Rulings.clean_rulings(rulings)
      # merge close rulings (TODO: decide how close is close?)
      # stitch rulings ("tips" are close enough)
      # delete lines that don't look like rulings (TODO: define rulingness)
    end

    def Rulings.detect_rulings(image_filename,
                               crop_x1, crop_y1, crop_x2, crop_y2)

      image = OpenCV::IplImage.load(image_filename,
                                    OpenCV::CV_LOAD_IMAGE_ANYCOLOR | OpenCV::CV_LOAD_IMAGE_ANYDEPTH)

      image.set_roi(OpenCV::CvRect.new(crop_x1, crop_y1,
                                       (crop_x2 - crop_x1).abs,
                                       (crop_y2 - crop_y1).abs))

      mat = image.to_CvMat

      mat = mat.BGR2GRAY if mat.channel == 3

      mat.save_image('/tmp/cropped.png')

      mat_canny = mat.canny(1, 50, 3)

      lines = mat_canny.hough_lines(:probabilistic,
                                    1,
                                    (Math::PI/180) * 45,
                                    200,
                                    200,
                                    10)

      lines = lines.to_a

      # filter out non vertical and non horizontal rulings
      # TODO check if necessary. would hough even detect diagonal lines with
      # the provided arguments, anyway?
      lines.reject! { |line|
        line.point1.x != line.point2.x and
        line.point1.y != line.point2.y
      }

      # rulings are returned relative to the image before cropping
      lines.map do |line|
        Ruling.new(line.point1.x + crop_x1, line.point1.y + crop_y1,
                   line.point2.x + crop_x1, line.point2.y + crop_y1)
      end

      # Hough non-probabilistic
      # wh = mat.size.width + mat.size.height
      # lines = mat_canny.hough_lines(:multi_scale, 1, Math::PI / 180, 100, 0, 0)
      # lines.map do |line|
      #   rho = line[0]; theta = line[1]
      #   a = Math.cos(theta); b = Math.sin(theta)
      #   x0 = a * rho; y0 = b * rho;
      #   [x0 + wh * (-b), y0 + wh*(a), x0 - wh*(-b), y0 - wh*(a)]
      # end
    end
  end
end
