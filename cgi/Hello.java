import java.applet.*;
import java.awt.*;

public class Hello extends Applet{
	public void paint(Graphics g){
		g.setColor(Color.red);
		g.drawString("Hello, World!",5,10);
	}
}
